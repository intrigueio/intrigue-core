require 'digest'
require 'fog-aws'
require 'thread'
require "json"


module Intrigue
module Handler

  class WriteToFileJson < Intrigue::Handler::Base

    def self.metadata
      {
        :name => "write_to_file_json",
        :pretty_name => "Write to File (JSON in ./tmp)",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)

      timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
      result = eval(result_type).first(id: result_id)
      puts "Memory efficent json handler called!"

      version = "v4"

      unless result.kind_of? Intrigue::Model::Project
        puts "Unable to call handler on this type: #{result}"
        return false
      end

      # export into data export db
      db = Intrigue::System::JsonDataExportFile.new(result.name, version)

      # Always use the project name when saving files for this project
      prefix_name = "#{result.name}/"

      result.issues.paged_each(rows_per_fetch: 500) do |i|
        # toss it in issues list
        db.store_issue i.export_hash
      end

      result.entities.paged_each(rows_per_fetch: 500) do |e|

        entity_name = e.name
        entity_type = e.type

        # Get the task results, as efficiently as possible. 
        eid = Intrigue::Model::Entity.last.id
        tr_ids = Intrigue::Model::EntitiesTaskResults.where(:entity_id => eid).select(:task_result_id).map{|x| x.task_result_id } 
        task_result_hash = Intrigue::Model::TaskResult.where(:id => tr_ids).select(:name, :task_name, :base_entity_id, :depth).map {
          |t| {  :name => t.name,
                 :task => t.task_name, 
                 :entity_type => "#{t.base_entity.type}",
                 :entity_name => "#{t.base_entity.name}",
                 :depth => t.depth } }

        # Get the ancestors, as efficiently as possible
        sr_ids = Intrigue::Model::TaskResult.where(:id => tr_ids).select(:scan_result_id).map{|x| x.scan_result_id}
        entity_ids = Intrigue::Model::ScanResult.where(:id => sr_ids).select(:base_entity_id).map{ |x| x.base_entity_id }
        ancestor_hash = Intrigue::Model::Entity.where(:id => entity_ids).select(:name, :type).map{|x| {name: x.name, type: x.type} }

        # create an export hash
        entity_hash =  {
          id: e.id,
          type: entity_type,
          name: entity_name,
          alias_group: e.alias_group_id,
          hidden: e.hidden,
          scoped: e.scoped,
          ancestors: ancestor_hash,
          deleted: e.deleted,
          details: e.details, #only send lite details (no extened)
          task_results: task_result_hash
        }

        # save off our entity now that we have a details file if we need it
        db.store_entity entity_hash

        # possible memory leak?
        entity_hash = nil
        e = nil
        
      end
    
      # clear queue
      puts "Clearing queue"
      entity_q = nil

      # close off our temp files
      puts "Closing off files"
      db.close_files
        
      ###
      ### Write Issues
      ###

      ### Convert the JSONL to a JSON File 
      issues_count = result.issues.count
      issues_per_file = 10000 # XXX
      count = 0
      
      ((issues_count / issues_per_file) + 1).times do 

        start_line = count*issues_per_file
        end_line = (count+1)*issues_per_file

        file_path = "#{$intrigue_basedir}/tmp/#{result.name}.#{timestamp}.issues.#{count}.json"
        File.open(file_path, "w").write db.dump_issues_json(start_line,end_line)
        count +=1
      end

      ###
      ### Write Entities
      ###

      ### Convert the JSONL to a JSON File 
      entities_count = result.entities.count
      entities_per_file = 10000 # XXX
      count = 0
      
      ((entities_count / entities_per_file) + 1).times do 

        start_line = count*entities_per_file
        end_line = (count+1)*entities_per_file

        # calculate the final file
        final = true if end_line > entities_count

        file_path = "#{$intrigue_basedir}/tmp/#{result.name}.#{timestamp}.entities.#{count}.json"
        File.open(file_path, "w").write db.dump_entities_json(start_line,end_line,final)
        count +=1
      end
      
      puts "Cleaning up"
      db.cleanup
    end

  end
end
end
