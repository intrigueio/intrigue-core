
# Simple logger class
module Intrigue
class ScanLog < Intrigue::Log

  def initialize(id, name)
    super(id, name)
    @type = "scan"

    puts "Scan log initialized with key #{key}"

    # Placeholder for storing results
    $intrigue_redis.set "scan_result:#{id}", "{}"
  end

end
end
