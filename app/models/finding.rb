module Intrigue
  module Model
    class Finding < Sequel::Model

      plugin :serialization, :json, :details
      many_to_one  :entity
      many_to_one  :project
      many_to_one  :task_result
      many_to_one  :scan_result

      def self.scope_by_project(project_name)
        named_project_id = Intrigue::Model::Project.first(:name => project_name).id
        where(:project_id => named_project_id)
      end

    end
  end
end
