
class CoreApp < Sinatra::Base

  def halt_unless_authenticated(user_key)
    if authenticate_system_api_call(user_key)
      return true
    else
      halt 401
    end
  end

  def authenticate_system_api_call(user_key)

    cleansed_key = URI.unescape("#{user_key}".strip)
    system_key = "#{Intrigue::Core::System::Config.config["credentials"]["api_key"]}".strip 

    if Intrigue::Core::System::Config.config["api_security"]
      if cleansed_key && (cleansed_key == system_key)
        return true
      end
    else 
      return true
    end
  
  false  
  end

  def add_standard_cors_headers
    headers 'Access-Control-Allow-Origin' => '*',
    'Access-Control-Allow-Methods' => ['OPTIONS','GET']
  end

  def get_json_payload
    @request.body.rewind
    begin 
      out = JSON.parse(@request.body.read).symbolize_keys
    rescue JSON::ParserError => e
      @request.body.rewind
      puts "ERROR! Bad request data #{@request.body.read}"
    end
  out
  end

  def wrap_core_api_response(message,result=nil)
    {
      success: !result.nil?,
      message: message,
      result: result
    }.to_json
  end

end