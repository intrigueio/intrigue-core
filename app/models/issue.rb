module Intrigue
  module Model

    class Issue < Sequel::Model
      plugin :validation_helpers
    
      many_to_one  :project
      many_to_one  :task_result
      many_to_one  :entity

      self.raise_on_save_failure = false

      def self.scope_by_project(project_name)
        where(:project => Intrigue::Model::Project.first(:name => project_name))
      end

      def validate
        super
        validates_unique([:project_id, :type, :entity_id])
      end

      def to_s
        "#{name} on #{entity.type} #{entity.name}"
      end
      
      ###
      ### Export!
      ###
      def export_hash
        {
          :type => details[:name],
          :pretty_name => details[:pretty_name],
          :name => details[:name],
          :identifiers =>  details[:identifiers],
          :category =>  details[:category],
          :severity =>  details[:severity],
          :status =>  details[:status],
          :scoped =>  details[:scoped],
          :description =>  details[:description],
          :remediation =>  details[:remediation],
          :references =>  details[:references],
          :entity_type => entity.type,
          :entity_name => entity.name,
          :entity_aliases => entity.aliases.map{|a| {:type => a.type, :name => a.name} },  
          :entity_alias_group_id => entity.alias_group_id,
          :details => details,
          :task_result => task_result.name,
          :task_result_entity_name => task_result.base_entity.name,
          :task_result_entity_type => task_result.base_entity.type
        }
      end

      def export_csv
        "#{type}, #{name}, #{severity}, #{status}, #{description.gsub(",",";")}, #{entity.type}, #{entity.name}, #{entity.alias_group_id}"
      end


      def export_json
        export_hash.to_json
      end

    end

  end
end
