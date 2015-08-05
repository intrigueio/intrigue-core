
# Simple logger class
module Intrigue
class ScanLog < Intrigue::Log

  def initialize(id, name)
    super(id, name)
    @type = "scan"

    puts "Scan log initialized with key #{key}"
  end

end
end
