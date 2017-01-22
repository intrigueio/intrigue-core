# There should only ever be one of these workers running, so
# this is started independently of the core subsystem. See
# util/background_workers.rb

#require 'sidekiq-unique-jobs'

module Intrigue
module Workers
class HandleResultWorker
  include Sidekiq::Worker
  sidekiq_options :queue => "app", :backtrace => true
  #sidekiq_options unique: :until_and_while_executing

  def perform
    puts "Starting background worker task for handlers... "

    global_config = Intrigue::Config::GlobalConfig.new

    while true # loop forever

      handle_all_task_results
      handle_all_scan_results

      # Wait before doing it again
      wait_time = global_config.config["intrigue_handler_processing_wait_time"]
      #puts "Waiting... #{wait_time}"
      sleep (wait_time || 60)

    end

  end

  def handle_all_scan_results
    # Handle all ScanResults
    Intrigue::Model::ScanResult.all.each do |scan_result|
      #puts "DEBUG Checking... #{scan_result.name}"

      # First check if the scan_result is already handled
      next if scan_result.handlers_complete

      # If not, check if we have handlers
      next unless scan_result.handlers.count > 0

      # We can't handle until all task results are complete, so gather
      # all of our task results and check if they're individually
      # complete
      incomplete_tasks = scan_result.task_results.select{|tr| tr.complete == false }

      # If so, mark the scan_result complete and handle the results
      if incomplete_tasks.count == 0
        #puts "DEBUG Handling... #{scan_result.name}"

        # we can mark this scan complete now
        scan_result.complete = true
        scan_result.save

        # Run handlers here
        scan_result.handlers.each do |handler_type|
          handler = Intrigue::HandlerFactory.create_by_type(handler_type)
          puts "Calling #{handler_type} handler on #{scan_result.name}"
          handler.process(scan_result)
        end

        # mark the handlers run
        scan_result.handlers_complete = true
        scan_result.save
      end
    end
  end

  def handle_all_task_results
    # Handle all TaskResults
    Intrigue::Model::TaskResult.all.each do |task_result|
      #puts "DEBUG Checking... #{task_result.name}"
      # Skip things that have been handled or are already
      # don't have handlers
      next if task_result.handlers_complete
      next unless task_result.handlers.count > 0

      if task_result.complete
        #puts "DEBUG Handling... #{task_result.name}"

        # run handlers here
        task_result.handlers.each do |handler_type|
          handler = Intrigue::HandlerFactory.create_by_type(handler_type)
          puts "Calling #{handler_type} handler on #{task_result.name}"
          handler.process(task_result)
        end

        # mark the handlers run
        task_result.handlers_complete = true
        task_result.save
      end
    end
  end

end
end
end

#Intrigue::Workers::HandleResultWorker.new.perform
