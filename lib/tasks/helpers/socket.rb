module Intrigue
module Task
module Socket 

  ## Source: Metasploit 
  ##
  ## Changes bit ordering of the provided value, using the provided size 
  ##
  ## @param addr [String] Value to be changed
  ## @param sizer [Numeric] the number of bits to adjust at a given time
  def change_endianness(value, size = 4)
    conversion = nil
    if size == 4
      conversion = [value].pack("V").unpack("N").first
    elsif size == 2
      conversion = [value].pack("v").unpack("n").first
    end
  conversion
  end

  ## Source: Rex::Socket
  ##
  ## Converts an integer address into ascii
  ##
  ## @param (see #addr_iton)
  ## @return (see #addr_ntoa)
  def addr_itoa(addr, v6=false)
    nboa = addr_iton(addr, v6)

  addr_ntoa(nboa)
  end

  ## Source: Rex::Socket
  ##
  ## Converts an integer into a network byte order address
  ##
  ## @param addr [Numeric] The address as a number
  ## @param v6 [Boolean] Whether +addr+ is IPv6
  def self.addr_iton(addr, v6=false)
    if(addr < 0x100000000 && !v6)
      return [addr].pack('N')
    else
      w    = []
      w[0] = (addr >> 96) & 0xffffffff
      w[1] = (addr >> 64) & 0xffffffff
      w[2] = (addr >> 32) & 0xffffffff
      w[3] = addr & 0xffffffff
      return w.pack('N4')
    end
  end

  ## Source: Rex::Socket
  ##
  ## Converts a network byte order address to ascii
  ##
  ## @param addr [String] Packed network-byte-order address
  ## @return [String] Human readable IP address.
  def addr_ntoa(addr)
    # IPv4
    if (addr.length == 4)
      return addr.unpack('C4').join('.')
    end

    # IPv6
    if (addr.length == 16)
      return compress_address(addr.unpack('n8').map{ |c| "%x" % c }.join(":"))
    end

    raise RuntimeError, "Invalid address format"
  end

end 
end
end
