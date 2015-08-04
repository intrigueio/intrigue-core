
# Simple logger class
class TaskLog < IntrigueLog

  def initialize(id, name, write_file=false)
    super(id, name)

    @type = "task"

    @write_file = write_file
    # We can also write to a file at the same time...
    if @write_file
      @outfile = File.open(File.join("log","#{@name}_#{@id}.log"), "a")
    end

  end

end
