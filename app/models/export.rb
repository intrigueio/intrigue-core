module Intrigue
  module Model
    class Export < Sequel::Model

      def self.scope_by_project(project_name)
        named_project_id = Intrigue::Model::Project.first(:name => project_name).id
        where(:project_id => named_project_id)
      end

      def self.generate
        raise "Override me!"
      end

    end
  end
end


module Intrigue
  module Model
    class ExportCsv < Intrigue::Model::Export

      def generate
        project = Intrigue::Model::Project.first(:id => project_id)
        x = project.entities

        #require 'pry'
        #binding.pry

        out = ""
        out << "Type,Name,Aliases,Details\n"
        x.each do |entity|
          alias_string = entity.aliases.each{|a| "#{a.type_string}##{a.name}" }.join(" | ")
          out << "#{entity.type_string},#{entity.name},#{alias_string},#{entity.detail_string}\n"
        end

        name = "CSV Export (#{DateTime.now})"

        set(:contents => out)
        save

      end

    end
  end
end
