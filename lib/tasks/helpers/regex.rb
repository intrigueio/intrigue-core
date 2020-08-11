module Intrigue
module Task
module Regex

  def match_regex(type, input)
    "#{input}" =~ _get_regex(type)
  end

  private

    def _get_regex(regex_type)
      if regex_type == :integer
        regex = /^-?\d+$/
      elsif regex_type == :boolean
        regex = /(true|false)/
      elsif regex_type == :alpha_numeric
        regex = /^[a-zA-Z0-9\_\:\;\(\)\,\?\.\-\_\/\~\=\ \,\#\?\*]*$/
      elsif regex_type == :alpha_numeric_list
        regex = /^[a-zA-Z0-9\_\:\;\(\)\,\?\.\-\_\/\~\=\ \#\?\$\*]*$/
      elsif regex_type == :numeric_list
        regex = /^[0-9\,]*$/
      elsif regex_type == :filename
        regex = /(?:\..*(?!\/))+/
      elsif regex_type == :netblock
        regex = netblock_regex
      elsif regex_type == :hostname
        regex = dns_regex
      elsif regex_type == :ip_address
        regex = ipv4_regex || ipv6_regex
      end

    regex
    end

end
end
end
