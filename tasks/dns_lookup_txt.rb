require 'dnsruby'
require 'whois'

class DnsLookupTxtTask < BaseTask

  def metadata
    { :version => "1.0",
      :name => "dns_lookup_txt",
      :pretty_name => "DNS TXT Lookup",
      :authors => ["jcran"],
      :description => "DNS TXT Lookup",
      :references => [
        "http://webmasters.stackexchange.com/questions/27910/txt-vs-spf-record-for-google-servers-spf-record-either-or-both",
        "https://community.rapid7.com/community/infosec/blog/2015/02/23/osint-through-sender-policy-framework-spf-records"
      ],
      :allowed_types => ["DnsRecord"],
      :example_entities => [{:type => "DnsRecord", :attributes => {:name => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" }
      ],
      :created_types => ["DnsRecord", "IpAddress", "Info", "NetBlock" ]
    }
  end

  def run
    super

    resolver = _get_option "resolver"
    domain_name = _get_entity_attribute "name"

    @task_log.log "Running TXT lookup on #{domain_name}"

    begin
      res = Dnsruby::Resolver.new(
      :recurse => true,
      :query_timeout => 5)

      res_answer = res.query(domain_name, Dnsruby::Types.TXT)

      # If we got a success to the query.
      if res_answer
        @task_log.good "TXT lookup succeeded on #{domain_name}:"
        @task_log.good "Answer:\n=======\n#{res_answer.to_s}======"


        # TODO - Parse for netbocks and hostnames

        #     res_answer.downcase.split("ipv4").
        #     create_entity NetBlock, :range

        # Create a finding for each
        unless res_answer.answer.count == 0
          res_answer.answer.each do |answer|
            answer.rdata.first.split(" ").each do |record|
              if record =~ /^include:.*/
                _create_entity "DnsRecord", :attributes => {:name => record.split(":").last}
              elsif record =~ /^ip4:.*/
                s = record.split(":").last
                if s.include? "/"
                  _create_entity "NetBlock", :attributes => {:name => s }
                else
                  _create_entity "IpAddress", :attributes => {:name => s }
                end
              elsif record =~ /^google-site-verification.*/
                _create_entity "Info", {:name => "DNS Verification Code", :type =>"Google", :content => record.split(":").last}
              elsif record =~ /^yandex-verification.*/
                _create_entity "Info", {:name => "DNS Verification Code", :type =>"Yandex", :content => record.split(":").last}
              end
            end

            _create_entity "Info", { :name => "TXT Record", :content => answer.to_s , :details => res_answer.to_s }

          end
        end

      end

    rescue Dnsruby::Refused
      @task_log.log "Zone Transfer against #{domain_name} refused."

    rescue Dnsruby::ResolvError
      @task_log.log "Unable to resolve #{domain_name}"

    rescue Dnsruby::ResolvTimeout
      @task_log.log "Timed out while querying #{domain_name}."

    rescue Exception => e
      @task_log.log "Unknown exception: #{e}"

    end
  end


end
