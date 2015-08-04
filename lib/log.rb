require 'redis'

# Simple logger class
class IntrigueLog

  def initialize(id,name)
    @id = id
    @name = name
    @redis = Redis.new
    @out = StringIO.new
  end

  attr_accessor :name

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

  def key
    "#{@type}:#{@id}"
  end

private
  def _log(message)

    # Write to IO stream
    @out.puts message

    # Write to STDOUT
    puts message

    # Write to Redis
    @redis.set key, @out.string

    #Write to file
    if @write_file
      @outfile.puts message
      @outfile.flush
    end

  end

end
