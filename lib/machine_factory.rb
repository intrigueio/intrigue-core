###
### Machine factory: Standardize the creation and validation of scans
###
module Intrigue
class MachineFactory

  def self.register(klass)
    @machines = [] unless @machines
    @machines << klass
  end

  def self.list
    @machines
  end

  def self.create_by_name(name)
    @machines.each { |s| return s if "#{s.metadata[:name]}" == "#{name}" }
  false
  end

  #
  # Check to see if this machine exists (check by name)
  #
  def self.has_machine?(name)
    @machines.each { |s| return true if "#{s.metadata[:name]}" == "#{name}" }
  false
  end

end
end
