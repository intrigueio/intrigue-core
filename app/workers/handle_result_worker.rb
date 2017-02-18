# There should only ever be one of these workers running, so
# this is started independently of the core subsystem. See
# util/background_workers.rb

require 'sidekiq-unique-jobs'

module Intrigue
module Workers
class HandleResultWorker
  include Sidekiq::Worker
  sidekiq_options :queue => "app", :backtrace => true

  def perform(id, force_handling)
    puts "HandleResultWorker #{id}: Starting background worker task for handlers... "

    # Get the scan_result & the incomplete tasks
    scan_result = Intrigue::Model::ScanResult.first(:id => id)

    # Make sure we actually have handlers before starting
    unless scan_result.handlers.count > 0
      puts "HandleResultWorker #{id}: Nothing to handle, no handlers set up. Returning..."
      scan_result.complete = true
      scan_result.save
      return
    end


    ### So... here we wait for the result's tasks to complete... unless we complete
    ### our tasks, or the user has specifically requested that we don't (This
    ### is handy in cases of requesting to handle the results via CLI)

    # default sleep length
    sleep_length = 60
    i = 0

    # Get our current number of incomplete tasks
    incomplete_task_count = scan_result.task_results.select{|tr| tr.complete == false }.count

    # and then check to make sure we're not done, or timed out, or forced
    until (incomplete_task_count == 0 || force_handling==true)
      puts "HandleResultWorker #{id}: Waiting for #{scan_result.name} to finish... #{incomplete_task_count}/#{scan_result.task_results.count} tasks."
      puts "HandleResultWorker #{id}: Duration... #{i*sleep_length} seconds"
      sleep sleep_length

      # Grab the record again, so we can make sure to have the latest info
      scan_result = Intrigue::Model::ScanResult.first(:id => id)
      incomplete_task_count = scan_result.task_results.select{|tr| tr.complete == false }.count
      i=i+1
    end

    # and then run the handlers
    puts "HandleResultWorker #{id}: All complete, handling... #{scan_result.name}"
    scan_result.handlers.each do |handler_type|
      handler = Intrigue::HandlerFactory.create_by_type(handler_type)
      puts "HandleResultWorker #{id}: Calling #{handler_type} handler on #{scan_result.name}"
      handler.process(scan_result)
    end

    # let's mark it complete if there's nothing else to do here.
    scan_result.handlers_complete = true
    scan_result.complete = true
    scan_result.save
  end

end
end
end
