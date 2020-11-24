
# usage
#
# j = JsonExportFile.new("/tmp/file.json")
# j.store_entity {test2: 'test2'} 
# j.write_and_close 
#
#
class JsonExportFile

  def initialize(fullpath=nil)
    @output_file = fullpath || "#{$intrigue_basedir}/tmp/json_export_#{rand(100000000000)}.json"
    @entity_count = 0
    @closed = false

    # prep file
    _write_and_flush_line @output_file, "["
  end

  def store_entity(entity)
    # increment 
    @entity_count+=1

    # add to the end of the list
    _write_and_flush_line @output_file, "#{entity.to_json},"
  end

  def write_and_close
    
    # only allow one write
    return nil if @closed

    # remove trailing commas
    if @entity_count > 0
      File.truncate(@output_file, File.size(@output_file) - 2) # new line and comma
    end

    # close it 
    _write_and_flush_line @output_file, "]"
    @closed = true

  @output_file 
  end

  private 

    def _write_and_flush_line(file,line)
      fe = File.open(file,"a")
      fe.sync = true
      fe.puts(line)
      fe.flush
      fe.close
    end

end

