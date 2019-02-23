module Intrigue
  module Model

    class Finding < Sequel::Model
      plugin :validation_helpers
      plugin :single_table_inheritance, :type
      plugin :serialization, :json, :details

      self.raise_on_save_failure = true

      def self.scope_by_project(project_name)
        named_project_id = Intrigue::Model::Project.first(:name => project_name).id
        where(:project_id => named_project_id)
      end


    end

  end
end
