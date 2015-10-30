require 'uri'
require 'net/http'

module Intrigue
class UriHttpAuthBrute < BaseTask

  include Intrigue::Task::Lists

  def metadata
    {
      :name => "uri_http_auth_brute",
      :pretty_name => "URI HTTP Auth Brute",
      :authors => ["jcran"],
      :description => "This task bruteforces authentication, given a URI requiring HTTP auth.",
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

    begin
      uri = _get_entity_attribute "name"

      # first things first, check to see if it's required at all
      response = http_get_auth_resource(uri,"not-a-real-username","not-a-real-password",10)
      unless response.class == Net::HTTPUnauthorized
        @task_result.log_error "No authentication required for #{uri}"
        return
      end

      # Otherwise, continue on, and check each cred (See list in Intrigue::Task::Lists)
      simple_web_creds.each do |cred|

       Timeout::timeout(10) do

        response = http_get_auth_resource(uri,cred["username"],cred["password"],10)

        case response
          when Net::HTTPOK
            @task_result.log_good "#{cred} on #{uri} authorized!"
            _create_entity "Info", "name" => "#{cred} on #{uri}"
          when Net::HTTPUnauthorized
            @task_result.log "#{cred} on #{uri} unauthorized."
          else
            @task_result.log "Got response #{response.inspect} on #{uri}"
        end

      end # end timeout
    end #end creds
   #rescue
   #  @task_result.log_error "Connection Failed: #{uri}"
   #rescue Timeout::Error
   #  @task_result.log_error "Unable to connect: #{uri}"
   end
 end


 def http_get_auth_resource(location, username,password, depth)

   unless depth > 0
     @task_result.log_error "Too many redirects"
     exit
   end

   uri = URI.parse(location)
   http = Net::HTTP.new(uri.host, uri.port)
   request = Net::HTTP::Get.new(uri.request_uri,{"User-Agent" => "Intrigue!"})
   request.basic_auth(username,password)
   response = http.request(request)

   if response == Net::HTTPRedirection
     @task_result.log "Redirecting to #{response['location']}"
     http_get_auth_resource(response['location'],username,password, depth-1)
   elsif response == Net::HTTPMovedPermanently
     @task_result.log "Redirecting to #{response['location']}"
     http_get_auth_resource(response['location'],username,password, depth-1)
   else
     @task_result.log "Got response: #{response}"
   end

 response
 end


end
end
