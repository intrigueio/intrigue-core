# Simple logger class
module Intrigue
module Model
class Log

  attr_accessor :id, :name, :string

  def initialize(id,name)
    @id = id
    @lookup_key = "#{key}:#{@id}"
    @name = name
    @stream = StringIO.new
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
    @stream.string
  end

  def to_json
    {
      "id" => @id,
      "name" => @name,
      "stream" => @stream.string
    }.to_json
  end

  def from_json(json)
    x = JSON.parse(json)
    @id = x["id"]
    @name = x["name"]
    @stream = StringIO.new
    @stream << x["stream"]
  end

  def to_s
    @stream.string
  end
  
  def save
    lookup_key = "#{key}:#{@id}"
    $intrigue_redis.set lookup_key, to_json
  end

  def self.find(id)
    lookup_key = "#{key}:#{id}"
    result = $intrigue_redis.get(lookup_key)
    raise "Unable to find #{lookup_key}" unless result

    # Create a new object
    s = self.new("nope","nope")
    # and load our json
    s.from_json(result)
    s.save
    # if we didn't find anything in the db, return nil
    return nil if s.name == "nope"
  # return the log
  s
  end

private
  def _log(message)

    # Write to IO stream
    @stream.puts message

    # Write to STDOUT
    puts message

    # Write to Redis
    save

    #Write to file
    if @write_file
      @streamfile.puts message
      @streamfile.flush
    end

  end

end
end
end
