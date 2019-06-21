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
      _log_good "TXT lookup succeeded on #{domain_name}:"
      _log_good "Answer:\n=======\n#{res_answer.to_s}======"

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
            #elsif record =~ /^google-site-verification.*/
            #  _create_entity "Info", {"name" => "DNS Verification Code", "type" =>"Google", "content" => #record.split(":").last}
            #elsif record =~ /^yandex-verification.*/
            #  _create_entity "Info", {"name" => "DNS Verification Code", "type" =>"Yandex", "content" => #record.split(":").last}
            end
          end

          # Log an info record with full detail
          _create_entity "Info", { :name => "TXT Record", :content => answer.to_s , :details => res_answer.to_s }

        end
      end

    end

    _log "done"
  end


end
end
end
