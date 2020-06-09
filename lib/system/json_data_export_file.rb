module Intrigue
module System
class JsonDataExportFile

  def initialize(name="", version=1, timestamp=Time.now.utc.strftime("%Y%m%d%H%M%S"))
    @version = version
    @name = name
    
    @entities_file = "#{$intrigue_basedir}/tmp/#{@name}_entities.#{timestamp}.tmp"
    @issues_file = "#{$intrigue_basedir}/tmp/#{@name}_issues.#{timestamp}.tmp"
  
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

  def dump_issues_json(start,finish)
    # dump out the hash, closing files as you go
    {
      "name" => "#{@name}",
      "ingest_at" => "#{@ingest_at}",
      "generated_at" => "#{DateTime.now}",
      "version" => "#{@version}",
      "issues" => File.open(@issues_file).readlines[start..finish].reject { 
        |s| s.strip.empty? }.compact.map{|x| 
        JSON.parse(x) },
      "start" => start, 
      "finish" => finish
    }.to_json
  end

  def dump_entities_json(start,finish, final=false)
    # dump out the hash, closing files as you go
    {
      "name" => "#{@name}",
      "ingest_at" => "#{@ingest_at}",
      "generated_at" => "#{Time.now.utc}",
      "version" => "#{@version}",
      "entities" => File.open(@entities_file).readlines[start..finish].reject { 
        |s| s.strip.empty? }.compact.map{|x| 
        JSON.parse(x) },
      "start" => start, 
      "finish" => finish
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
end
end