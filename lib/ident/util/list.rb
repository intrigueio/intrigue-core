#!/usr/bin/env ruby
require_relative "../lib/intrigue-ident"
include Intrigue::Ident

def list_checks
  Intrigue::Ident::CheckFactory.all.map{|x| x.new.generate_checks("x") }.flatten
end

list_checks.sort_by{|c| "#{c[:vendor]}"}.each {|c| puts " - #{c[:vendor]} #{c[:product]}"}
