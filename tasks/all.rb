require_relative 'base'

current_folder = File.expand_path('../', __FILE__) # get absolute directory
Dir["#{current_folder}/*.rb"].each {|f| require_relative f}
