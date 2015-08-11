# Simple logger class
module Intrigue
module Model
class Log

  attr_accessor :id, :name, :string

  def initialize(id,name)
    @id = id
    @lookup_key = "#{key}:#{@id}"
    @name = name
    @string = StringIO.new
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
    @string.string
  end

  def key
    "#{@type}:#{@id}"
  end

  def to_json
    {
      "id" => @id,
      "name" => @name,
      "string" => @string.string
    }
  end

  def from_json(json)
    x = JSON.parse(json)
    @id = x["id"]
    @lookup_key = "#{key}:#{@id}"
    @name = x["name"]
    @string = StringIO.new
    @string << x["string"]
  end

  def to_s
    #@out.string
    to_json
  end

  def save
    $intrigue_redis.set @lookup_key, to_json
  end

  def self.find(id)

    # Do the lookup out of redis
    s = ScanResultLog.new("nope","nope")
    s.from_json($intrigue_redis.get("#{key}:#{id}"))

    # if we didn't find anything in the db, return nil
    return nil if s.name == "nope"

  # return the scan log
  s
  end

private
  def _log(message)

    # Write to IO stream
    @string.puts message

    # Write to STDOUT
    puts message

    # Write to Redis
    $intrigue_redis.set @lookup_key, to_json

    #Write to file
    if @write_file
      @outfile.puts message
      @outfile.flush
    end

  end

end
end
end
