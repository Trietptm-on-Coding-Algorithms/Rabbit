
require 'lib/metasm/metasm'

module Rabbit

	class Debugger < Metasm::WinDbgAPI
		#include Rabbit::Utils # contains code for symbol look ups and various other useful stuff

		def initialize(target, debug_child = false)
			# check if we have debug privs
			if not Metasm::WinOS.get_debug_privilege
				puts("[error] - Failed to get debug privilege, quiting.")
				exit(-1)
			end

			# make sure target is passed properly
			if target.nil? or target.empty?
				puts Metasm::WinOS.list_processes.sort_by { |proc| proc.pid }
				abort 'target needed'
			end

			# check if target is a path if it is look for existing processes matching the process name and get the pid
			# if there is no pid start the process
			if target.class == String
				exe = target[ target.rindex('\\')+1, target.length-target.rindex('\\') ]
				proc = Metasm::WinOS.find_process(target)

				if proc
					@pid = proc.pid
				else # make sure that target is a path, create the process if its not already running (Taken from metasm WinDbgAPI code)
					if File.stat.executable?(target)
						flags = Metasm::WinAPI::DEBUG_PROCESS
						flags |= Metasm::WinAPI::DEBUG_ONLY_THIS_PROCESS if not debug_child
						startupinfo = [17*[0].pack('L').length, *([0]*16)].pack('L*')
						processinfo = [0, 0, 0, 0].pack('L*')
						Metasm::WinAPI.createprocessa(nil, target, nil, nil, 0, flags, nil, nil, startupinfo, processinfo)
						@pid = processinfo.unpack('LLL')[2]
					else
						puts("[error] - #{target} is not an executable file.")
						exit(-1)
					end
				end
			end

			# we should have a valid pid at this time
			@dbg = super(@pid, debug_child)
		end

		def detach
			Metasm::WinAPI.debugactiveprocessstop(@pid)
		end

		def handler_exception(pid, tid, info)
		end

		def handler_loaddll(pid, tid, info)
		end

		def handler_unloaddll(pid, tid, info)
		end

		def handler_endprocess(pid, tid, info)
			puts "#{pid}:#{tid} process died"
			prehandler_endprocess(pid, tid, info)
			Metasm::WinAPI::DBG_CONTINUE
		end

		def prehandler_endprocess(pid, tid, info)
			@hprocess.delete pid
			@hthread.delete pid
			@mem.delete pid
		end

	end

end