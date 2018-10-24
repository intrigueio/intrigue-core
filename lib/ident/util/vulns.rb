#!/usr/bin/env ruby
require_relative "../lib/intrigue-ident"
include Intrigue::Ident

def cpe_search(cpe_string)
  Intrigue::Ident::Cpe.new(cpe_string).vulns
end

cpe_search(ARGV[0]).each do |v|
  puts "#{v["CVE_data_meta"]["ID"]}:\n#{v["description"]["description_data"].first["value"]}\n\n"
end