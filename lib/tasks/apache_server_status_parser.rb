module Intrigue
module Task
class ApacheServerStatusParser < BaseTask

  def self.metadata
    {
      :name => "apache_server_status_parser",
      :pretty_name => "Apache 'Server Status' Parser",
      :authors => ["jcran"],
      :description => "Given a uri, this task will look for a server-status page and if found, parse it to create entities",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "intrigue"} }
      ],
      :allowed_options => [],
      :created_types => ["DnsRecord", "Uri"]
    }
  end

  def run
    super
    uri = _get_entity_name

    # remove trailing slash if it exists
    uri = uri[0..-2] if uri[-1] == "/"

    server_status_page = http_get_body("#{uri}/server-status");nil

    unless server_status_page && server_status_page =~ /Server Version/
      _log "Unable to find status page, returning"
      return
    end

    info_hash = {}
    xmatch = server_status_page.match(/<dl><dt>Server Version:(.*)<\/dt>/)
    info_hash[:server_version] = xmatch.captures.first.strip if xmatch

    xmatch = server_status_page.match(/<dt>Server MPM:(.*)<\/dt>/)
    info_hash[:server_mpm] = xmatch.captures.first.strip if xmatch

    xmatch = server_status_page.match(/<dt>Server Built:(.*)/)
    info_hash[:server_built] = xmatch.captures.first.strip if xmatch

    xmatch = server_status_page.match(/<dt>Current Time:(.*)<\/dt>/)
    info_hash[:current_time] = xmatch.captures.first.strip if xmatch

    xmatch = server_status_page.match(/<dt>Restart Time:(.*)<\/dt>/)
    info_hash[:restart_time] = xmatch.captures.first.strip if xmatch

    xmatch = server_status_page.match(/<dt>Server uptime:(.*)<\/dt>/)
    info_hash[:server_uptime] = xmatch.captures.first.strip if xmatch
    
    xmatch = server_status_page.match(/<dt>Server load:(.*)<\/dt>/)
    info_hash[:server_load] = xmatch.captures.first.strip if xmatch

    xmatch = server_status_page.match(/<dt>Total accesses:(.*)- Total Traffic:.*<\/dt>/)
    info_hash[:total_accesses] = xmatch.captures.first.strip if xmatch

    xmatch = server_status_page.match(/<dt>Total accesses:.*- Total Traffic:(.*)<\/dt>/)
    info_hash[:total_traffic] = xmatch.captures.first.strip if xmatch

    xmatch = server_status_page.match(/<dt>Total accesses:(.*)<\/dt>/)
    info_hash[:total_accesses] = xmatch.captures.first.strip.to_i if xmatch
    
    xmatch = server_status_page.match(/<dt>CPU Usage:(.*)<\/dt>/)
    info_hash[:cpu_usage] = xmatch.captures.first.strip if xmatch
    
    xmatch = server_status_page.match(/<dt>(\d+) requests currently being processed, \d+ idle workers<\/dt>/)
    info_hash[:current_requests] = xmatch.captures.first.strip if xmatch

    server_status_page.match(/<dt>\d+ requests currently being processed, (\d+) idle workers<\/dt>/)
    info_hash[:idle_workers] = xmatch.captures.first.strip if xmatch

    info_hash[:workers] = "#{info_hash[:current_requests]}".to_i + "#{info_hash[:idle_workers]}".to_i
    
    # Set the detail
    _set_entity_detail "apache_server_status", info_hash

    gathered_uris = []

    sleep_sec = 10

    10.times do |t|
      server_status_page = http_get_body("#{uri}/server-status");nil

      # <td nowrap>GET /content/dam/MGM/akamai/healthcheck.svg HTTP/1.1</td></tr>
      server_status_page.each_line do |line|
        m = line.match(/<td nowrap>(.*)<\/td><td nowrap>(.*)<\/td><\/tr>/)
        if m 
          vhost_cell, request_cell = m.captures.map{|x| x.strip};nil 
          
          #puts "Vhost: #{vhost_cell.split(":").first}"
          vhost = vhost_cell.split(":").first

          #puts "Method: #{request_cell.split(" ")[0]}"
          http_method = request_cell.split(" ")[0]

          #puts "Requested Path: #{request_cell.split(" ")[1..-1]}"
          request_path = request_cell.split(" ")[1]
          request_path = nil if http_method == "OPTIONS"
          request_path = nil if http_method == "NULL"

          gathered_uris << { method: "#{http_method}", uri: "#{uri.split(":").first}://#{vhost}#{request_path}" }
          
          # set these temporarily
          _set_entity_detail "apache_server_status_uris", gathered_uris 

          # create entity
          _create_entity "DnsRecord", "name" => vhost

        end
      end;nil

      _log "sleeping #{sleep_sec} seconds before checking again"
      sleep sleep_sec
    end

    _set_entity_detail "apache_server_status_uris", gathered_uris 

  end

end
end
end
