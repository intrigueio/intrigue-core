require_relative '../core'

$stdout.sync = true

puts "Starting handler worker..."
Intrigue::Workers::HandleResultWorker.new.perform
