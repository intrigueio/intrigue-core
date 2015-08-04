
# Simple logger class
class ScanLog < IntrigueLog

  def initialize(id, name)
    super(id, name)
    @type = "scan"

    puts "Scan log initialized with key #{key}"
  end

end
