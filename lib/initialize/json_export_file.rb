
# usage
#
# j = JsonExportFile.new
# j.store_entity {test: 'test'} 
# j.store_entity {test2: 'test2'} 
# j.write_and_close ("/tmp/file.json")
#
#
class JsonExportFile

  def initialize
    @temp_file = "#{$intrigue_basedir}/tmp/#{rand(100000000000)}.tmp"
    @entity_count = 0
    @closed = false
    # prep files
    _write_and_flush_line @temp_file, "["
  end

  def store_entity(entity)
    # increment 
    @entity_count+=1

    # add to the end of the list
    _write_and_flush_line @temp_file, "#{entity.to_json},"
  end

  def write_and_close(path)
    
    # only allow one write
    return false if @closed

    # remove trailing commas
    if @entity_count > 0
      File.truncate(@temp_file, File.size(@temp_file) - 2) # new line and comma
    end

    # close it 
    _write_and_flush_line @temp_file, "]"
    @closed = true

    f = File.open(path,"w")
    f.puts _dump_json
    f.flush
    f.close

    # clean up 
    File.delete(@temp_file)
  end

  private 

    def _dump_json # dump out the hash, closing files as you go
      {
        "generated_at" => "#{DateTime.now}",
        "entity_count" => @entity_count,
        "entities" => JSON.parse("#{File.open(@temp_file).read}"),
      }.to_json
    end


    def _write_and_flush_line(file,line)
      fe = File.open(file,"a")
      fe.sync = true
      fe.puts(line)
      fe.flush
      fe.close
    end

end

