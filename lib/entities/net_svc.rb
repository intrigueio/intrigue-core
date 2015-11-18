module Intrigue
module Entity
class NetSvc < Intrigue::Model::Entity

  def metadata
    {
      :description => "TODO"
    }
  end


  def validate
    @details["ip_address"].to_s =~ /^.*$/ &&
    @details["port_num"].to_s =~ /^\d{1,5}$/ &&
    @details["proto"].to_s =~ /^(tcp|udp)$/
  end

  def form
    output = super
    output << "IP Address: <input type=\"text\" name=\"attrib_ip_address\" value=#{ _escape_html @details["ip_address"]}><br/>"
    output << "Port Num: <input type=\"text\" name=\"attrib_port_num\" value=#{ _escape_html @details["port_num"]}><br/>"
    output << "Proto: <input type=\"text\" name=\"attrib_proto\" value=#{ _escape_html @details["proto"]}><br/>"
  output
  end

end
end
end
