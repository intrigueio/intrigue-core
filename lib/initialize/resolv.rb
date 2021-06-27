require "resolv"
class Resolv::DNS::Resource::IN::CAA < Resolv::DNS::Resource
    TypeValue = 257
    ClassValue = IN::ClassValue
    ClassHash[[TypeValue, ClassValue]] = self

    def initialize(flags, tag, value)
    # https://tools.ietf.org/html/rfc8659#section-4.1
    #    +0-1-2-3-4-5-6-7-|0-1-2-3-4-5-6-7-|
    #    | Flags          | Tag Length = n |
    #    +----------------|----------------+...+---------------+
    #    | Tag char 0     | Tag char 1     |...| Tag char n-1  |
    #    +----------------|----------------+...+---------------+
    #    +----------------|----------------+.....+----------------+
    #    | Value byte 0   | Value byte 1   |.....| Value byte m-1 |
    #    +----------------|----------------+.....+----------------+
    @flags = flags
    @tag = tag
    @value = value
    end

    ##
    # Critical Flag

    attr_reader :flags

    ##
    # Property identifier

    attr_reader :tag

    ##
    # A sequence of octets representing the Property Value

    attr_reader :value

    def encode_rdata(msg)
    msg.put_bytes(@flags)
    msg.put_string(@tag)
    msg.put_bytes(@value)
    end

    def self.decode_rdata(msg)
    flags = msg.get_bytes(1)
    tag = msg.get_string
    value = msg.get_bytes
    new(flags, tag, value)
    end
 end
