module Intrigue
module Workers
class HandleResultWorker
  include Sidekiq::Worker
  sidekiq_options :queue => "app", :backtrace => true

  def perform(klass, id)
    result = resolve_class(klass,id)

    return unless result
    return unless result.handlers.count > 0

    # Wait until its complete
    until result.complete
      #puts "sleeping on #{result.export_json}"
      sleep 3

      result = resolve_class(klass,id)
      return unless result
      return unless result.handlers.count > 0

      if result.kind_of? Intrigue::Model::ScanResult
        # check to see if all tasks are complete
        x = result.task_results.select{|tr| tr.complete == false }

        # If so, mark it complete
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

  def resolve_class(klass, id)
    if klass == "Intrigue::Model::TaskResult"
      result = Intrigue::Model::TaskResult.where(:id => id).first
    elsif klass == "Intrigue::Model::ScanResult"
      result = Intrigue::Model::ScanResult.where(:id => id).first
    end
  result
  end

end
end
end
