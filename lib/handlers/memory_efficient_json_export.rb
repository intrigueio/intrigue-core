require 'digest'
require 'fog-aws'
require 'thread'
require "json"


module Intrigue
module Handler

  class JsonDataExportFile

    def initialize(name,version)
      @version = version
      @name = name

      @nonce = "#{Time.now.strftime("%y%m%d%H%M%S")}"

      @prefix = "intrigue_export_#{name}"
      @entities_file = "#{$intrigue_basedir}/tmp/#{name}.entities-#{@nonce}.list"
      @issues_file = "#{$intrigue_basedir}/tmp/#{name}.issues-#{@nonce}.list"
    
      @file_mutex = Mutex.new

      # prep files
      _write_and_flush @entities_file
      _write_and_flush @issues_file

      # set time here, because ingest will now be 
      # chunked into pieces... 
      @ingest_at = DateTime.now
    end

    def cleanup
      File.delete(@entities_file)
      File.delete(@issues_file)
    end

    def close_files
      # close files
      _write_and_flush @entities_file
      _write_and_flush @issues_file
    end

    def store_entity(entity_hash)
      # add to the end of the list
      _write_and_flush @entities_file, "#{entity_hash.to_json}\n"
      entity_hash = nil
    true
    end

    def store_issue(issue_hash)
      # add to the end of the list
      _write_and_flush @issues_file, "#{issue_hash.to_json}\n"
      entity_hash = nil
    true
    end

    def dump_issues_json
      # dump out the hash, closing files as you go
      {
        "name" => "#{@name}",
        "ingest_at" => "#{@ingest_at}",
        "generated_at" => "#{DateTime.now}",
        "version" => "#{@version}",
        "issues" => File.open(@issues_file).readlines.reject { 
          |s| s.strip.empty? }.compact.map{|x| 
          JSON.parse(x) }
      }.to_json
    end

    def dump_entities_json
      # dump out the hash, closing files as you go
      {
        "name" => "#{@name}",
        "ingest_at" => "#{@ingest_at}",
        "generated_at" => "#{DateTime.now}",
        "version" => "#{@version}",
        "entities" => File.open(@entities_file).readlines.reject { 
          |s| s.strip.empty? }.compact.map{ |x| 
          JSON.parse(x) }
      }.to_json
    end

    private 

      def _write_and_flush(file,line=nil)
        fe = File.open(file,"a")
        fe.puts line
        line = nil
        fe.flush
        fe.close
      true
      end

  end

  class MemoryEfficientJsonExport < Intrigue::Handler::Base

    def self.metadata
      {
        :name => "memory_efficient_json_export",
        :pretty_name => "Memory Efficient JSON Export",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)

      @debug = false

      result = eval(result_type).first(id: result_id)
      puts "memory efficent json handler called!"

      version = "v4"

      unless result.kind_of? Intrigue::Model::Project
        puts "Unable to call handler on this type: #{result}"
        return false
      end

      # export into data export db
      db = Intrigue::Handler::JsonDataExportFile.new(result.name, version)

      # Always use the project name when saving files for this project
      prefix_name = "#{result.name}/#{DateTime.now.to_date.to_s.gsub("-","_")}/"

      result.issues.each do |i|
        # toss it in issues list
        db.store_issue i.export_hash
      end

      result.entities.each do |e|

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
          ancestors: [],
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

      puts "Done storing entities"

      # clear queue
      puts "Clearing qeue"
      entity_q = nil

      # close off ou(r specific files
      puts "Closing off files"
      db.close_files

      # dumping files
      db.dump_entities_json
      db.dump_issues_json

      puts "Cleaning up"
      db.cleanup
    end

  end
end
end
