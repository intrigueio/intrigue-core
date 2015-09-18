require 'uri'
require 'net/http'

module Intrigue
class UriHttpAuthBrute < BaseTask

  def metadata
    {
      :name => "uri_http_auth_brute",
      :pretty_name => "URI HTTP Auth Brute",
      :authors => ["jcran"],
      :description => "This task bruteforces http authentication, given a URI.",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "attributes" => {"name" => "http://www.intrigue.io"}}
      ],
      :allowed_options => [  ],
      :created_types =>  ["Credential", "Info"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    creds = [
      {"username" => "guest", "password" => "guest"},
      {"username" => "test", "password" => "test"},
      {"username" => "cisco", "password" => "cisco"},
      {"username" => "admin", "password" => "admin"},
      {"username" => "anonymous", "password" => "anonymous"}
    ]

    begin
      uri = _get_entity_attribute "name"

      # first things first, check to see if it's required at all
      response = http_get_authd(uri,"not-a-real-username","not-a-real-password",10)
      unless response.class == Net::HTTPUnauthorized
        @task_log.error "No authentication required for #{uri}"
        return
      end

      # Otherwise, continue on, and check each cred
      creds.each do |cred|

       Timeout::timeout(10) do

        response = http_get_authd(uri,cred["username"],cred["password"],10)

        case response
          when Net::HTTPOK
            @task_log.good "#{cred} on #{uri} authorized!"
            _create_entity "Info", "name" => "#{cred} on #{uri}"
          when Net::HTTPUnauthorized
            @task_log.log "#{cred} on #{uri} unauthorized."
          else
            @task_log.log "Got response #{response.inspect} on #{uri}"
        end

      end # end timeout
    end #end creds
   #rescue
   #  @task_log.error "Connection Failed: #{uri}"
   #rescue Timeout::Error
   #  @task_log.error "Unable to connect: #{uri}"
   end
 end


 def http_get_authd(location, username,password, depth)

   unless depth > 0
     @task_log.error "Too many redirects"
     exit
   end

   uri = URI.parse(location)
   http = Net::HTTP.new(uri.host, uri.port)
   request = Net::HTTP::Get.new(uri.request_uri,{"User-Agent" => "Intrigue!"})
   request.basic_auth(username,password)
   response = http.request(request)

   if response == Net::HTTPRedirection
     @task_log.log "Redirecting to #{response['location']}"
     http_get_authd(response['location'],username,password, depth-1)
   elsif response == Net::HTTPMovedPermanently
     @task_log.log "Redirecting to #{response['location']}"
     http_get_authd(response['location'],username,password, depth-1)
   else
     @task_log.log "Got response: #{response}"
   end

 response
 end


end
end
