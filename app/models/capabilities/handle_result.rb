module Intrigue
module Model
module Capabilities
module HandleResult

  # This capability gives us the ability to launch handlers as soon
  # as we're marked complete! (Yes, we have to be "complete", or it will wait -
  # forever if necessary)

  def handle_result(id, force_handling=false)
    # Start a new worker ... note that this is a persistent, long term
    # worker that won't (shouldn't) end until it's complete
    Intrigue::Workers::HandleResultWorker.perform_async(id, force_handling)
  end

end
end
end
end
