require_relative '../core'

puts "Starting handler worker..."
Intrigue::Workers::HandleResultWorker.perform_async
