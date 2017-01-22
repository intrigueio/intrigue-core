require_relative '../core'

puts "Starting handler worker..."
worker = Intrigue::Workers::HandleResultWorker.new
worker.perform_async
