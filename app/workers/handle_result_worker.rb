# There should only ever be one of these workers running, so
# this is started independently of the core subsystem. See
# util/background_workers.rb

require 'sidekiq-unique-jobs'

module Intrigue
module Workers
class HandleResultWorker
  include Sidekiq::Worker
  sidekiq_options :queue => "app", :backtrace => true

  def perform(id)
    puts "HandleResultWorker: Starting background worker task for handlers... "


    # if there's not going to be any new information, let's just return
    if scan_result.handlers_complete
      puts "returning, handlers have already been marked complete"
      return
    end

    # Get the scan_result & the incomplete tasks
    scan_result = Intrigue::Model::ScanResult.first(:id => id)

    incomplete_task_count = scan_result.task_results.select{|tr| tr.complete == false }.count

    # Make sure we actually have handlers before starting
    unless scan_result.handlers.count > 0
      puts "HandleResultWorker: Nothing to handle, no handlers set up. Returning..."
      return
    end

=begin
    until incomplete_task_count == 0
      puts "HandleResultWorker: Waiting for #{scan_result.name} to finish... #{incomplete_task_count}/#{scan_result.task_results.count} tasks."
      sleep 10

      # Grab the record again
      scan_result = Intrigue::Model::ScanResult.first(:id => id)
      incomplete_task_count = scan_result.task_results.select{|tr| tr.complete == false }.count
    end

    # If we don't have any, mark the scan_result complete
    puts "HandleResultWorker: All complete, handling... #{scan_result.name}"
=end

    # and then run the handlers
    scan_result.handlers.each do |handler_type|
      handler = Intrigue::HandlerFactory.create_by_type(handler_type)
      puts "HandleResultWorker: Calling #{handler_type} handler on #{scan_result.name}"
      handler.process(scan_result)
    end

    # let's mark it complete if there's nothing else to do here.
    if incomplete_task_count == 0
      # ...and mark the handlers run
      scan_result.handlers_complete = true
      scan_result.complete = true
      scan_result.save
    end

  end

end
end
end
