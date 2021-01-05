require 'open3'

module Intrigue
  module Task
    module Popen
      DEFAULT_PROCESS_TIMEOUT = 600 # seconds

      ###
      ### DO NOT USE THIS DIRECTLY, USE _unsafe_system!!
      ### 
      def popen_with_timeout(cmd, timeout=DEFAULT_PROCESS_TIMEOUT, path="/tmp")
        raise "Commands must be provided as an array of strings" unless cmd.is_a?(Array)

        # inherit our environment
        vars = ENV

        # save the current working directory
        vars['PWD'] = path
        
        FileUtils.mkdir_p(path) unless File.directory?(path)

        # Create pipes we can read 
        rout, wout = IO.pipe
        rerr, werr = IO.pipe

        pid = Process.spawn(vars, *cmd, out: wout, err: werr, chdir: path, pgroup: true)
        # stderr and stdout pipes can block if stderr/stdout aren't drained: https://bugs.ruby-lang.org/issues/9082
        # Mimic what Ruby does with capture3: https://github.com/ruby/ruby/blob/1ec544695fa02d714180ef9c34e755027b6a2103/lib/open3.rb#L257-L273
        out_reader = Thread.new { rout.read }
        err_reader = Thread.new { rerr.read }

        begin
          # close write ends so we could read them
          wout.close
          werr.close
          
          # wait for completion
          status = process_wait_with_timeout(pid, timeout)

          # Don't copy `popen` which merges stderr into output
          cmd_output = out_reader.value
          err_output = err_reader.value 
          
          # return stdout, stderr and exit status
          [cmd_output, err_output, status.exitstatus]
        rescue TimeoutError => e
          kill_process_group_for_pid(pid)
          raise e
        ensure
          wout.close unless wout.closed?
          werr.close unless werr.closed?

          # rout is shared with out_reader. To prevent an exception in that
          # thread, kill the thread before closing rout. The same goes for rerr
          # below.
          out_reader.kill
          rout.close

          err_reader.kill
          rerr.close
        end
      end

      def process_wait_with_timeout(pid, timeout)
        deadline = Time.now + timeout.to_i # add seconds, get a deadline
        wait_time = 0.01

        while deadline > Time.now
          sleep(wait_time)
          _, status = Process.wait2(pid, Process::WNOHANG)

          return status unless status.nil?
        end

        raise TimeoutError, "Timeout waiting for process ##{pid}"
      end

      def kill_process_group_for_pid(pid)
        Process.kill("KILL", -pid)
        Process.wait(pid)
      rescue Errno::ESRCH
      end

    end
  end
end