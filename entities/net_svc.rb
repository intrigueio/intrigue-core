module Intrigue
module Entity
class NetSvc < Base

  def metadata
    {
      :type => "NetSvc",
      :required_attributes => ["ip_address","port_num","proto"]
    }
  end

  def validate(attributes)
    attributes["ip_address"].to_s =~ /^.*$/ &&
    attributes["port_num"].to_s =~ /^\d{1,5}$/ &&
    attributes["proto"].to_s =~ /^(tcp|udp)$/
  end

  def form
    output = super
    output << "IP Address: <input type=\"text\" name=\"attrib_ip_address\" value=#{ _escape_html @attributes[:ip_address]}><br/>"
    output << "Port Num: <input type=\"text\" name=\"attrib_port_num\" value=#{ _escape_html @attributes[:port_num]}><br/>"
    output << "Proto: <input type=\"text\" name=\"attrib_proto\" value=#{ _escape_html @attributes[:proto]}><br/>"
  output
  end

end
end
end
