# Simple logger class
class TaskLog

  attr_accessor :name
  attr_accessor :out

  def initialize(id, name="anonymous", write_file=false)
    @name = name
    @out = StringIO.new
    @write_file = write_file
    #
    # We can also write to a file at the same time...
    #
    if @write_file
      @outfile = File.open(File.join("log","#{@name}_#{id}.log"), "a")
    end
  end

  def log(message)
    _log "[ ] #{@name}: " << message
  end

  ######
  def debug(message)
    _log "[D] #{@name}: " << message
  end

  def good(message)
    _log "[+] #{@name}: " << message
  end

  def error(message)
    _log "[-] #{@name}: " << message
  end
  ######

  def to_text
    @out.string
  end

private
  def _log(message)
    @out.puts message
    puts message
    if @write_file
      @outfile.puts message
      @outfile.flush
    end
  end

end
