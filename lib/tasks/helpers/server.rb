require 'webrick'

module Intrigue
module Task
module Server

class SsrfResponder

  include Sidekiq::Worker
  sidekiq_options :queue => "app", :backtrace => true

  def self.start_and_background(port=55555)
    self.perform_async port
  end

  def perform(port)
    begin
      @server = ::WEBrick::HTTPServer.new(:Port => port)
      @server.mount "/", SsrfResponderServerBehavior
      @server.start
    rescue Errno::EADDRINUSE => e
      # just return if it's already running
    end
  end

end

class SsrfResponderServerBehavior < ::WEBrick::HTTPServlet::AbstractServlet
  def do_GET(request, response)

    #
    # this request can come with a specific id,
    # which we should be able to to correlate
    #
    task_result_id = request.query["int_id"]
    parameter = request.query["int_param"]
    e = Intrigue::Model::TaskResult.first(:id => task_result_id ).base_entity
    ssrf_params = e.get_detail("ssrf_params") || []
    ssrf_params << parameter
    e.set_detail "ssrf_params", ssrf_params

    response.status = 200
  request.body
  end

  def do_POST(request, response)

    #
    # this request can come with a specific id,
    # which we should be able to to correlate
    #
    task_result_id = request.query["int_id"]
    parameter = request.query["int_param"]
    e = Intrigue::Model::TaskResult.first(:id => task_result_id ).base_entity
    ssrf_params = e.get_detail("ssrf_params") || []
    ssrf_params << parameter
    e.set_detail "ssrf_params", ssrf_params

    response.status = 200
  request.body
  end
end

end
end
end
