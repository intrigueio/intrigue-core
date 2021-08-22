module Intrigue
module Core
module Model

  class Issue < Sequel::Model
    plugin :validation_helpers
    plugin :timestamps

    many_to_one  :project
    many_to_one  :task_result
    many_to_one  :entity

    self.raise_on_save_failure = false

    def self.scope_by_project(project_name)
      where(:project => Intrigue::Core::Model::Project.first(:name => project_name))
    end

    def validate
      super
      validates_unique([:entity_id, :name, :project_id, :source])
    end

    def uuid
      project_name = self.project.name if self.project
      project_name = "missing_project" unless project_name

      out = "#{project_name}##{self.name}#{source}##{entity.uuid}"

      Digest::SHA2.hexdigest(out)
    end

    def to_s
      "#{name} on #{entity.type} #{entity.name}"
    end

    def to_v1_api_hash(full=false)
      if full
        export_hash
      else
        {
          :type => name,
          :name => name,
          :category => category,
          :severity => severity,
          :status => status,
          :scoped => scoped,
          :source => source,
          :pretty_name => details["pretty_name"],
          :entity_type => entity.type,
          :entity_name => entity.name
        }
      end
    end
    ###
    ### Export!
    ###
    def export_hash
      {
        :type => name,
        :name => name,
        :category => category,
        :severity => severity,
        :status => status,
        :scoped => scoped,
        :source => source,
        :description =>  description,
        :pretty_name => details["pretty_name"],
        :identifiers =>  details["identifiers"],
        :remediation =>  details["remediation"],
        :references =>  details["references"],
        :entity_type => entity.type,
        :entity_name => entity.name,
        :entity_aliases => entity.aliases.map{|a| {"type" => a.type, "name" => a.name} },
        :entity_alias_group_id => entity.alias_group_id,
        :details => details,
        :task_result => "#{task_result.name if task_result}",
        :task_result_entity_name => "#{task_result.base_entity.name if task_result}",
        :task_result_entity_type => "#{task_result.base_entity.type if task_result}"
      }
    end

    def export_csv
      "#{type}, #{name}, #{severity}, #{status}, #{description.gsub(",",";")}, #{entity.type}, #{entity.name}, #{entity.alias_group_id}"
    end

    def export_json
      export_hash.merge("generated_at" => "#{Time.now.utc.iso8601}").to_json
    end


  end

end
end
end