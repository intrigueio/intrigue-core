require 'async/dns'

class CoreDnsServer < Async::DNS::Server
  def process(name, resource_class, transaction)
    @resolver ||= Async::DNS::Resolver.new([
      [:udp, '8.8.8.8', 53], 
      [:tcp, '8.8.8.8', 53] ])
    transaction.passthrough!(@resolver)
  end
end

server = CoreDnsServer.new([[:udp, '127.0.0.1', 8081]])

server.run