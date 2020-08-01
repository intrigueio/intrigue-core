require 'fileutils'

module Intrigue
module Core
module System
  class JsonDataExportFile

    attr_accessor :entities_file
    attr_accessor :issue_file

    def initialize(name, version=1, timestamp=Time.now.utc.strftime("%Y%m%d%H%M%S"))
      @version = version
      @name = name
      @uuid = nil
      
      @entities_file = "#{$intrigue_basedir}/tmp/#{@name}_entities.#{timestamp}.jsonl"
      @issues_file = "#{$intrigue_basedir}/tmp/#{@name}_issues.#{timestamp}.jsonl"

      FileUtils.touch @entities_file
      FileUtils.touch @issues_file
    
      # set time here, because ingest will now be 
      # chunked into pieces... 
      @ingest_at = Time.now.utc
    end

    def cleanup
      File.delete(@entities_file)
      File.delete(@issues_file)
    end

    def set_uuid(uuid_from_user)
      @uuid = uuid_from_user
    end

    def close_files
      # nothing to do 
    end

    def store_entity(entity_hash)
      # add to the end of the list
      _write_and_flush @entities_file, "#{entity_hash.to_json}\n"
    true
    end

    def store_issue(issue_hash)
      # add to the end of the list
      _write_and_flush @issues_file, "#{issue_hash.to_json}\n"
    true
    end

    def dump_issues_json(start, finish)
      return nil unless File.exist? @issues_file 
      # dump out the hash, closing files as you go
      {
        "name" => "#{@name}",
        "ingest_at" => "#{@ingest_at}",
        "collection_run_uuid" => "#{@uuid}",
        "generated_at" => "#{Time.now.utc}",
        "version" => "#{@version}",
        "issues" => File.open(@issues_file).readlines[start..finish].reject { |s|
          s.strip.empty? }.compact.map{|x| JSON.parse(x) },
        "start" => start, 
        "finish" => finish
      }.to_json
    end

    def dump_entities_json(start, finish, final=false)
      return nil unless File.exist? @entities_file 
      # dump out the hash, closing files as you go
      {
        "name" => "#{@name}",
        "ingest_at" => "#{@ingest_at}",
        "collection_run_uuid" => "#{@uuid}",
        "generated_at" => "#{Time.now.utc}",
        "version" => "#{@version}",
        "entities" => File.open(@entities_file).readlines[start..finish].reject { |s|
          s.strip.empty? }.compact.map{|x| JSON.parse(x) },
        "final" => final,
        "start" => start, 
        "finish" => finish
      }.to_json
    end

    private 

      def _write_and_flush(file, line=nil)
        return false unless File.exist? file 
        File.open(file,"a"){|x| x.puts(line); x.flush; }
      true
      end

  end
end
end
end