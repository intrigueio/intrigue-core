module Intrigue
module Task
class SearchCensys < BaseTask

  def self.metadata
    {
      :name => "search_censys",
      :pretty_name => "Search Censys.io",
      :authors => ["jcran"],
      :description => "This task hits the Censys API and finds matches",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [{"type" => "String", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord","FtpServer","SslCertificate"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    begin

      # Make sure the key is set
      uid = _get_global_config "censys_uid"
      secret = _get_global_config "censys_secret"
      entity_name = _get_entity_name

      unless uid && secret
        _log_error "No credentials?"
        return
      end

      # Attach to the censys service & search
      censys = Censys::Api.new(uid,secret)

      ## Grab IPv4 Results
      response = censys.search("ip:#{entity_name}","ipv4")
      response["results"].each do |r|
        next unless r
        _log "Got result: #{r}"

        if r
          # Go ahead and create the entity
          #ip = r["_source"]["ip"]
          #ip_entity = _create_entity "IpAddress", { "name" => "#{ip}", "source" => "censys", "censys_details" => r }

          # Where we can, let's create additional entities from the scan results
          if r["protocols"]
            r["protocols"].each do |p|

              # Pull out the protocol
              port = p.split("/").first.to_i # format is like "80/http"
              _create_network_service_entity(@entity, port, "tcp", {
                :censys_details => r
              })

            end # iterate through ports
          end # if r["_source"]["protocols"]
        end # if r["_source"]
      end # if r

=begin
      ["certificates"].each do |search_type|
        response = censys.search(entity_name,search_type)
        response["results"].each do |r|
          _log "Got result: #{r}"
          if r["parsed.subject_dn"]

            _create_entity "SslCertificate", "name" => r["parsed.subject_dn"], "additional" => r

            # Pull out the CN and create a name
            if r["parsed.subject_dn"].kind_of? Array
              r["parsed.subject_dn"].each do |x|
                host = x.split("CN=").last.split(",").first
                _create_entity "IpAddress", "name" => host if host
              end
            else
              _create_entity "IpAddress", "name" => r["parsed.subject_dn"]
            end
          end
        end
      end
=end

    # TODO -Should we expect any details when searching type "websites" ?

    rescue RuntimeError => e
      _log_error "Runtime error: #{e}"
    end

  end # end run()

end # end Class
end
end
