module Intrigue
  module Model

    class Issue < Sequel::Model
      plugin :validation_helpers
        plugin :serialization, :json, :details

      many_to_one  :project
      many_to_one  :task_result
      many_to_one  :entity

      self.raise_on_save_failure = false

      def self.scope_by_project(project_name)
        where(:project => Intrigue::Model::Project.first(:name => project_name))
      end

      def validate
        super
        validates_unique([:project_id, :type, :name])
      end
      
    end

  end
end
