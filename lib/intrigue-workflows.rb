
module Intrigue
  class Workflow

    def initialize(hash)
      @hash = hash
    end

    def definition
      @hash[:definition]
    end

    def description
      @hash[:name]
    end

    def depth
      @hash[:depth]
    end

    def enrichment
      @hash[:enrichment]
    end

    def flow
      @hash[:flow]
    end

    def name
      @hash[:name]
    end

    def pretty_name
      @hash[:pretty_name]
    end

    def user_selectable
      @hash[:user_selectable]
    end

    # Example:
    #
    #   "name": "intrigueio_precollection",
    #   "pretty_name": "Intrigue.io Pre-Collection",
    #   "passive": true,
    #   "user_selectable": false,
    #   "authors": ["jcran"],
    #   "description": "This workflow performs a VERY light passive ...",
    #   "flow" : "recursive",
    #   "depth": 4,
    #   "enrichment": {
    #     "AwsS3Bucket": [],
    #     "Domain": [ "enrich/domain" ]
    #     ...
    #   }
    #   "definition": {
    #     "AwsS3Bucket": [],
    #     "Domain": [{
    #       "task": "enumerate_nameservers",
    #       "options": []
    #     }
    #   ...
    #
    def to_h
      @hash
    end

    def enrichment_defined?
      !enrichment.nil?
    end

    def enrichment_for_entity_type(entity_type_string)
      enrichment[entity.type_string]
    end

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

    def pre_process_options(options=[], entity, task_result)
      out = options.map do |hash|

        k = hash.keys.first
        v = hash.values.first

        ### Our accepted variables
        if v =~ /^__seed_list__$/ ## current seed list
          v = entity.project.seeds.select_map(:name).join(",")
        end

        # Options shoudl be in his format for a task
        { "name" => k, "value" => v }

      end
    out
    end

    def start(entity, task_result)
      # sanity check before sending us off
      return unless entity && task_result

      # lookup what we need to do in the definition, and do the right thing
      if flow == "recursive"

        tasks_to_schedule = definition[entity.type_string]
        return unless tasks_to_schedule

        # now go through each task to call and call it
        tasks_to_schedule.each do |t|

          task_name = t["task"]
          task_options = t["options"] || []

          options = pre_process_options(task_options, entity, task_result)

          auto_scope =  t["auto_scope"]

          # start the task
          start_recursive_task(task_result, task_name, entity, options, auto_scope)
        end

      end

    end

     ###
    ### Helper method for starting a task run, unaware of workflow, but handy to have here
    ###
    def start_recursive_task(old_task_result, task_name, entity, options=[], auto_scope=false)
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

  end
end

#
# First, a simple factory interface
#
module Intrigue
  class WorkflowFactory

    # Provide the full list of workflows
    def self.workflow_definitions(check_user_definitions=true, load_paths=[])
      out = []

      # add default paths (accounting for private if it exists)
      load_paths << "#{$intrigue_basedir}/lib/workflows"
      load_paths << $intrigue_core_private_workflow_directory if $intrigue_core_private_workflow_directory

      # Load default templates
      load_paths.each do |path|
        Dir.glob("#{path}/*.yml").each do |f|
          template = YAML.load_file(f)
          out << template.symbolize_keys!
        end
      end

      #
      # pull user workflows (requires core)
      #
      
      if defined?(Intrigue::Core::Model)
        out.concat(Intrigue::Core::Model::Workflow.all.map{|x| x.to_h })   
      end

      out
    end

    # loads both system and user defined
    def self.create_workflow_by_name(name)
      wf = workflow_definitions.find{|x| x[:name] == name }
    Intrigue::Workflow.new(wf) if wf
    end

    def self.user_selectable_workflows
      wf = workflow_definitions.select{|x|
        x[:user_selectable] }.map{|wf| Intrigue::Workflow.new(wf) }
    end

  end
end