module Intrigue
module Task
class DnsLookupTxt < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "dns_lookup_txt",
      :pretty_name => "DNS TXT Lookup",
      :authors => ["jcran"],
      :description => "DNS TXT Lookup",
      :references => [
        "http://webmasters.stackexchange.com/questions/27910/txt-vs-spf-record-for-google-servers-spf-record-either-or-both"
      ],
      :allowed_types => ["Domain","DnsRecord"],
      :type => "discovery",
      :passive => true,
      :example_entities => [{"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["IpAddress", "Info", "NetBlock" ]
    }
  end

  def run
    super

    domain_name = _get_entity_name

    _log "Running TXT lookup on #{domain_name}"

    res_answer = collect_txt_records

    # If we got a success to the query.
    if res_answer

      # Create a finding for each
      unless res_answer.answer.count == 0
        res_answer.answer.each do |answer|
          answer.rdata.first.split(" ").each do |record|

            if record =~ /^include:.*/
              _create_entity "IpAddress", {"name" => record.split(":").last}
            elsif record =~ /^ip4:.*/
              s = record.split(":").last
              if s.include? "/"
                _create_entity "NetBlock", {"name" => s }
              else
                _create_entity "IpAddress", {"name" => s }
              end
            end
            
          end
        end
      end

      _set_entity_detail "txt_records", res_anwer.answer
    end
  end


end
end
end
