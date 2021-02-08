#
# Finally, source in all the issues, becasue this lets this folder stand 
# alone and be published as a gem (since it's helpful to get this info out in the world)
#

require_relative 'all_base'

issues_folder= File.expand_path('..', __FILE__) # get absolute directory
puts "Sourcing intrigue issues from  #{issues_folder}"
Dir["#{issues_folder}/issues/*.rb"].each {|f| require_relative f}

# Load all checks
tasks_folder = File.expand_path('../checks', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }