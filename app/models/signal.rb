module Intrigue
  module Model
    class Signal < Sequel::Model

      plugin :serialization, :json, :details

      many_to_many :entities
      many_to_one  :project

      def self.scope_by_project(project_name)
        named_project_id = Intrigue::Model::Project.first(:name => project_name).id
        where(:project_id => named_project_id)
      end

    end
  end
end
