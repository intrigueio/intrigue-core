module Intrigue
  module Model
    class Export < Sequel::Model

      def self.scope_by_project(project_name)
        named_project_id = Intrigue::Model::Project.first(:name => project_name).id
        where(:project_id => named_project_id)
      end

    end
  end
end
