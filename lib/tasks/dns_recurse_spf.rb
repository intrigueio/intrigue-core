module Intrigue
module Task
class DnsRecurseSpf < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "dns_recurse_spf",
      :pretty_name => "DNS SPF Recursive Lookup",
      :authors => ["markstanislav","jcran"],
      :description => "Check the SPF records of a domain (recursively) and create entities",
      :references => [
        "http://www.openspf.org/",
        "https://community.rapid7.com/community/infosec/blog/2015/02/23/osint-through-sender-policy-framework-spf-records"
      ],
      :allowed_types => ["Domain","DnsRecord"],
      :type => "discovery",
      :passive => true,
      :example_entities => [{"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["Domain", "IpAddress", "NetBlock"]
    }
  end

  def run
    super

    dns_name = _get_entity_name
    _log "Running SPF lookup on #{dns_name}"

    # Run a lookup on the entity
    lookup_txt_record(dns_name)
    _log "done!"

  end

  def create_spf_domain(spf_data)
    # Create a domain, accounting for tld
    domain_name = parse_domain_name(spf_data)
    _create_entity "Domain", { "name" => domain_name, "unscoped" => true }
  end 

  def lookup_txt_record(dns_name)

    result = resolve(dns_name, [Resolv::DNS::Resource::IN::TXT])

    # If we got a success to the query.
    if result
      _log_good "TXT lookup succeeded on #{dns_name}!"
      #_log_good "Result:\n=======\n#{result.to_s}======"

      # Make sure there was actually a record
      unless result.count == 0

        # Iterate through each answer
        result.each do |r|

          r["lookup_details"].each do |response|

            response["response_record_data"].split(",").each do |record|

              _log "Got record: #{record}"

              if record =~ /^v=spf1/

                _log_good "SPF Record: #{record}"

                # We have an SPF record, so let's process it
                record.split(" ").each do |data|

                  _log "Processing SPF component: #{data}"

                  if data =~ /^v=spf1/
                    next #skip!

                  elsif data =~ /^include:.*/
                    _log_good "Parsing 'include' directive: #{data}"
                    spf_data = data.split(":").last

                    # create a domain
                    create_spf_domain spf_data

                    # RECURSE!
                    lookup_txt_record spf_data

                  elsif data =~ /^redirect=.*/
                    _log_good "Parsing 'redirect' directive: #{data}"
                    spf_data = data.split("=").last

                    # create a domain
                    create_spf_domain spf_data

                    # RECURSE!
                    lookup_txt_record spf_data

                  elsif data =~ /^exists:.*/ 
                    _log_good "Parsing 'exists' directive: #{data}"
                    spf_data = data.split("=").last
                    spf_data = spf_data.gsub("%{i}.","") # https://pastebin.com/ug0xHf6H
                    
                    # create a domain
                    create_spf_domain spf_data

                    # RECURSE!
                    lookup_txt_record spf_data

                  elsif data =~ /^ptr:.*/
                    _log_good "Parsing 'ptr' directive: #{data}"
                    spf_data = data.split(":").last

                    # create a domain
                    create_spf_domain spf_data  

                    # RECURSE!
                    #lookup_txt_record spf_data

                    # Create an issue here? PTR is a "do not use" type
                    # https://www.sparkpost.com/blog/spf-authentication/

                    # Excerpt: 
                    #
                    # A final mechanism, “ptr” existed in the original specification for SPF, 
                    # but has been declared “do not use” in the current specification. The ptr 
                    # mechanism was used to declare that if the sending IP address had a DNS PTR 
                    # record that resolved to the domain name in question, then that IP address 
                    # was authorized to send mail for the domain.
                    #
                    # The current status of this mechanism is that it should not be used. However, 
                    # sites doing SPF validation must accept it as valid.

                  elsif data =~ /^ip4:.*/
                    _log_good "Parsing 'ipv4' directive: #{data}"
                    range = data.split(":").last

                    if data.include? "/"
                      _create_entity "NetBlock", {"name" => range, "unscoped" => true }
                    else
                      _create_entity "IpAddress", {"name" => range, "unscoped" => true }
                    end

                  end
                end
              
              end

            end
          end
        end

        _log "No more records"
      end
    else
      _log "Lookup failed, no result"
    end
  end


end
end
end
