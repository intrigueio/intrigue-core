module Intrigue
module Task
  class ShellCommand

    @stdout     = nil
    @stderr     = nil
    @pid        = nil
    @exitstatus = nil

    def initialize(stdout, stderr, process)
      @stdout     = stdout
      @stderr     = stderr
      @pid        = process.pid
      @exitstatus = process.exitstatus
    end

    def stdout
      @stdout
    end

    def stderr
      @stderr
    end

    def exit_status
      @exitstatus
    end

    def pid
      @pid
    end
  
  def self.execute(command)
    command_stdout = nil
    command_stderr = nil
    process = Open3.popen3(ENV, command + ';') do |stdin, stdout, stderr, thread|
      stdin.close
      stdout_buffer   = stdout.read
      stderr_buffer   = stderr.read
      command_stdout  = stdout_buffer if stdout_buffer.length > 0
      command_stderr  = stderr_buffer if stderr_buffer.length > 0
      thread.value # Wait for Process::Status object to be returned
    end
    return ShellCommand.new(command_stdout, command_stderr, process)
  end

  end
end
end 
