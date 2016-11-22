###
### Scan factory: Standardize the creation and validation of scans
###
module Intrigue
class ScanFactory

  def self.register(klass)
    @scans = [] unless @scans
    @scans << klass
  end

  def self.list
    available_scans
  end

  def self.allowed_scans_for_entity_type(entity_type)
    available_scans.select {|scan_class| scan_class if scan_class.metadata[:allowed_types].include? entity_type}
  end

  private

  def self.available_scans
    @scans
  end

end
end
