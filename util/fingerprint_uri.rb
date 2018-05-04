require_relative "../core"
include Intrigue::Task::Web
uri = ARGV[0] || "https://www.google.com"
puts fingerprint_uri uri
