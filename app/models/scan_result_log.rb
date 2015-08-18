
# Simple logger class
module Intrigue
module Model
class ScanResultLog < Intrigue::Model::Log

  def self.key
    "scan_result_log"
  end

  def key
    "#{Intrigue::Model::ScanResultLog.key}"
  end

  def initialize(id, name)
    super(id, name)
    @type = "scan"
  end

end
end
end
