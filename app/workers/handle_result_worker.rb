module Intrigue
module Workers
class HandleResultWorker
  include Sidekiq::Worker
  sidekiq_options :queue => "app", :backtrace => true

  def perform(klass, id)

    # Get the right class
    if "#{klass}" == "Intrigue::Model::TaskResult"
      result = Intrigue::Model::TaskResult.where(:id => id).first
    elsif "#{klass}" == "Intrigue::Model::ScanResult"
      result = Intrigue::Model::ScanResult.where(:id => id).first
    end
    return unless result
    return unless result.handlers.count > 0

    # Wait until its complete
    until result.complete
      #puts "sleeping on #{result.export_json}"
      sleep 3

      # Get the right class
      if "#{klass}" == "Intrigue::Model::TaskResult"
        result = Intrigue::Model::TaskResult.where(:id => id).first
      elsif "#{klass}" == "Intrigue::Model::ScanResult"
        result = Intrigue::Model::ScanResult.where(:id => id).first
      end
      return unless result.handlers.count > 0


      # check to see if the scan is complete
      if result.kind_of? Intrigue::Model::ScanResult
        x = result.task_results.select{|tr| tr.complete == false }
        #puts "Waiting on result: #{x}"
        if x.length == 0
          result.complete = true
          result.save
        end
      end
    end

    # Then for each of the associated handler types
    result.handlers.each do |handler_type|
      handler = HandlerFactory.create_by_type(handler_type)
      handler.process(result)
    end

  end

end
end
end
