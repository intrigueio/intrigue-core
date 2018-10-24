#!/usr/bin/env ruby
require_relative "../lib/intrigue-ident"
include Intrigue::Ident
url = ARGV[0]
debug = ARGV[1] || nil
puts "Checking... #{url}"
matches = generate_requests_and_check(url)

if debug
  puts "Debug: #{url}"
  response = _http_request :get, "#{url}"
  puts "Headers:"
  response.each_header {|x| puts " - #{x}: #{response[x]}" }
  puts "Body:"
  puts response.body
end

puts "Results: "
matches.each{|x| puts " - #{x["cpe"]}" } if matches
puts "Done! #{matches.count} matches"
