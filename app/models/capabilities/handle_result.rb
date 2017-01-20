module Intrigue
module Model
module Capabilities
module HandleResult

  # This capability gives us the ability to launch our handlers as soon
  # as we're marked complete! (Yes, we have to be "complete", or it will wait -
  # forever if necessary)


  def handle_result

    # Start a new generation
    Intrigue::Workers::HandleResultWorker.perform_async(self.class,self.id) if handlers

  end

end
end
end
end
