require_relative '../core'
require 'eventmachine'

# Note that this will block current thread.
begin
  EventMachine.run {
    EventMachine.start_server "127.0.0.1", 8081, EventMachine::DnsResolver
  }
rescue RuntimeError => e 
  puts "Event machine loop can be started once: #{e}"
rescue FiberError => e
  puts "Caught fiber error, safe to ignore: #{e}"
end
