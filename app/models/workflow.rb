module Intrigue
module Core
module Model  
class Workflow < Sequel::Model

  plugin :timestamps
  plugin :serialization, :json, :definition
  plugin :validation_helpers

  def validate
    super
    validates_unique([:name])
  end

  ###
  ### ###################################################################
  ###

  def self.load_default_workflows
    Dir.glob("#{$intrigue_basedir}/data/workflows/*.json").each do |f|
      template = JSON.parse(File.open("#{f}","r"))
      create_from_template(template)
    end
  end

  ### 
  ### Assumes we're handed a hash, and creates/stores the template
  ###
  def self.create_from_template(template)
    
    # set a sensible default
    template["depth"] = 5 unless template["depth"]

    # create a worfklow from the template, note that symbolize only gets the 
    # top level hash keys 
    t = template.symbolize_keys!
    w = Intrigue::Core::Model::Workflow.update_or_create(t.except(:definition))
    w.definition = t[:definition]
    w.save_changes
  end

  ###
  ### ###################################################################
  ###

  ###
  ### Returns a calculated value based on all tasks
  ###
  def passive?

    # only if know how to handle this
    #return false unless flow == "recursive"
  
    out = false # default
    
    # Check if each task is passive by looking at its metadata
    tasks = definition.values.flatten.map{|x| x["task"] }
    out = true if tasks.map{|t| TaskFactory.class_by_name(t).metadata[:passive] }.all? true
  
  out
  end
  
  def to_hash
    {
      name: name,
      pretty_name: pretty_name,
      user_selectable: user_selectable,
      maintainer: maintainer,
      description: description,
      flow: flow, 
      passive: self.passive?,
      definition: definition
    }
  end

  def start(entity, task_result)
    # sanity check before sending us off
    return unless entity && task_result

    # lookup what we need to do in the definition, and do the right thing
    if type == "recursive"
      
      tasks_to_call = definition[entity.type_string]

      # now go through each task to call and call it 
      tasks_to_call.each do |t|
        task_name = t["task"]
        options = t["options"]
        auto_scope =  t["auto_scope"]

        # start the task
        Intrigue::Core::Model::Workflow.start_recursive_task(
            task_result, task_name, entity, options, auto_scope)
      end

    end 

  end

  ###
  ### Helper method for starting a task run, unaware of workflow, but handy to have here
  ###
  def self.start_recursive_task(old_task_result, task_name, entity, options=[], auto_scope=false)
    project = old_task_result.project

    # check to see if it already exists, return nil if it does
    existing_task_result = Intrigue::Core::Model::TaskResult.first(
      :project => project,
      :task_name => "#{task_name}",
      :base_entity_id => entity.id
    )

    if existing_task_result && (existing_task_result.options == options)
      # Don't schedule a new one, just notify that it's already scheduled.
      return nil
    else

      task_class = Intrigue::TaskFactory.create_by_name(task_name).class
      task_forced_queue = task_class.metadata[:queue]

      new_task_result = start_task(task_forced_queue || "task_autoscheduled", 
                          project,
                          old_task_result.scan_result.id,
                          task_name,
                          entity,
                          old_task_result.depth - 1,
                          options,
                          old_task_result.handlers,
                          old_task_result.scan_result.workflow,
                          old_task_result.auto_enrich,
                          auto_scope)

    end

  new_task_result
  end


=begin

  TODO... 
   - change flow -> type
   - change recurse -> definition
   - remove passive (should be calculated)

	"name": "intrigueio_precollection",
	"pretty_name": "Intrigue.io Pre-Collection",
	"passive": true,
	"user_selectable": false,
	"authors": ["jcran"],
	"description": "This workflow performs a VERY light passive enumeration for organizations. Start with a Domain or NetBlock.",
  "flow" : "recursive",
  "depth": 4,
	"definition": {
		"AwsS3Bucket": [],
		"Domain": [{
				"task": "enumerate_nameservers",
				"options": []
			},
=end

=begin
    extend Intrigue::Core::System::Helpers
    extend Intrigue::Task::Data

    
=end

end
end
end
end