require 'digest'
require 'thread'
require "json"

module Intrigue
module Handler

  class DataExportFile

    def initialize(name,version)
      @version = version
      @name = name

      @nonce = "#{rand(100000000000)}"

      @prefix = "intrigue_export_#{name}"
      @entities_file = "#{$intrigue_basedir}/tmp/#{name}.entities-#{@nonce}.list"
      @issues_file = "#{$intrigue_basedir}/tmp/#{name}.issues-#{@nonce}.list"
      @entity_mutex = Mutex.new
      @issue_mutex = Mutex.new

      # prep files
      _write_and_flush @entities_file, "["
      _write_and_flush @issues_file, "["
    end

    def cleanup
      File.delete(@entities_file)
      File.delete(@issues_file)
    end

    def close_files(entity_count,issue_count)

      # remove trailing comma
      if entity_count > 0
        puts "Truncating entities file since we have #{entity_count} entities"
        File.truncate(@entities_file, File.size(@entities_file) - 2) # new line and comma
      end

      # prep files
      _write_and_flush @entities_file, "]"

      # remove trailing comma 
      if issue_count > 0
        puts "Truncating issues file since we have #{issue_count} issues"
        File.truncate(@issues_file, File.size(@issues_file) - 2) # new line and comma
      end

      # add a ]
      _write_and_flush @issues_file, "]"
    end

    def store_entity(entity_hash)
      # add to the end of the list
      _write_and_flush @entities_file, "#{entity_hash.to_json},"
    end

    def store_issue(issue_hash)
      # add to the end of the list
      _write_and_flush @issues_file, "#{issue_hash.to_json},"
    end

    def dump_json
      # dump out the hash, closing files as you go
      {
        "name" => "#{@name}",
        "generated_at" => "#{DateTime.now}",
        "version" => "#{@version}",
        "issues" => JSON.parse("#{File.open(@issues_file).read}"),
        "entities" => JSON.parse("#{File.open(@entities_file).read}"),
        "graph_json" => {}.to_json
      }.to_json
    end

    def write_file
      f = File.open("#{$intrigue_basedir}/tmp/#{@name}-#{@nonce}.json","w")
      f.puts dump_json
      f.flush
      f.close
    end

    private 
      def _write_and_flush(file,line)
        fe = File.open(file,"a")
        fe.sync = true
        fe.puts(line)
        fe.flush
        fe.close
      end

  end

  class JsonExport < Intrigue::Handler::Base

    def self.metadata
      {
        :name => "json",
        :pretty_name => "JSON Export",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)

      result = eval(result_type).first(id: result_id)
      puts "JSON exporter called!"

      version = "v4"

      unless result.kind_of? Intrigue::Model::Project
        puts "Unable to call exporter on this type: #{result}"
        return false
      end

      puts "#{result.name} Calling exporter on: #{result.name} project"
      puts "#{result.name} Calling exporter on entities: #{result.entities.count}"

      # export into data export db
      db = Intrigue::Handler::DataExportFile.new(result.name, version)
      
      # Always use the project name when saving files for this project
      prefix_name = "#{result.name}/"

      result.issues.each do |i|
        puts "#{result.name} exporting issue: #{i.name}"
       
        # toss it in issues list 
        db.store_issue i.to_hash
      end


      # for each entity we have
      puts "#{result.name} Getting entities..."
      entity_q = result.entities.inject(Queue.new, :push)

      workers = (0...9).map do
      Thread.new do
        begin
          thread_id = "#{rand(1000000000)}"

          while e = entity_q.pop(true)

            puts "Thread #{thread_id}, #{result.name} packaging entity: #{e.type}##{e.name}"

            task_results = e.task_results.map {|t| { :name => t.name, :depth => t.depth } }

            entity_name = e.name
            entity_type = e.type

            full_details = e.details

            # create an export hash
            entity_hash =  {
              :id => e.id,
              :type => entity_type,
              :name => entity_name,
              :alias_group => e.alias_group_id,
              :hidden => e.hidden,
              :scoped => e.scoped,
              :ancestors => e.ancestors,
              :deleted => e.deleted,
              :details => full_details,
              :task_results => task_results
            }

            # save off our entity now that we have a details file if we need it
            db.store_entity entity_hash
            
          end

        rescue ThreadError => e
          puts "Thread #{thread_id} Hit thread error: #{e}"
        end
      end
      end; "ok"
      workers.map(&:join); "ok"

      # close off ou(r specific files
      puts "Closing off files"
      db.close_files(result.entities.count, result.issues.count)
    
      # dump a debug file 
      puts "Dumping the file"
      db.write_file
  
      # notify
      Intrigue::NotifierFactory.default.each { |x| 
        x.notify("#{result.name} collection complete! Wrote #{result.entities.count} entities.") }

      puts "Cleaning up"
      db.cleanup
    end

  end
end
end

