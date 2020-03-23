###
### Task factory: Standardize the creation and validation of tasks
###
module Intrigue
  class TaskFactory
  
    def self.register(klass)
      @tasks = [] unless @tasks
      @tasks << klass
    end
  
    def self.list
      @tasks
    end
  
    def self.allowed_tasks_for_entity_type(entity_type)
      @tasks.select {|task_class| task_class if task_class.metadata[:allowed_types].include? entity_type}
    end
    #
    # XXX - can :name be set on the class vs the object
    # to prevent the need to call "new" ?
    #
    def self.include?(name)
      @tasks.each do |t|
        if (t.metadata[:name] == name)
          return true
        end
      end
    false
    end
  
    #
    # XXX - can :name be set on the class vs the object
    # to prevent the need to call "new" ?
    #
    def self.create_by_name(name)
      @tasks.each do |t|
        if (t.metadata[:name] == name)
          return t.new # Create a new object and send it back
        end
      end
      ### XXX - exception handling? This should return a specific exception.
      raise "No task with the name: #{name}!"
    end
  
    #
    # XXX - can :name be set on the class vs the object
    # to prevent the need to call "new" ?
    #
    def self.create_by_pretty_name(pretty_name)
      @tasks.each do |t|
        if (t.metadata[:pretty_name] == pretty_name)
          return t.new # Create a new object and send it back
        end
      end
  
      ### XXX - exception handling? Should this return an exception?
      raise "No task with the name: #{name}!"
    end
  
  end
end
  


### Mixins with common task functionality
require_relative 'tasks/helpers/generic'
require_relative 'tasks/helpers/web'
tasks_folder = File.expand_path('../tasks/helpers', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load all discovery tasks
require_relative 'tasks/base'
tasks_folder = File.expand_path('../tasks', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load enrichment functfions
tasks_folder = File.expand_path('../tasks/enrich', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load import tasks
tasks_folder = File.expand_path('../tasks/import', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load vuln check tasks
tasks_folder = File.expand_path('../tasks/threat', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# Load vuln check tasks
tasks_folder = File.expand_path('../tasks/vulns', __FILE__) # get absolute directory
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }
