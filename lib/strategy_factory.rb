###
### Strategy factory: Standardize the creation and validation of scans
###
module Intrigue
class StrategyFactory

  def self.register(klass)
    @strategies = [] unless @strategies
    @strategies << klass
  end

  def self.list
    @strategies
  end

  def self.create_by_name(name)
    @strategies.each { |s| return s if "#{s.metadata[:name]}" == "#{name}" }
  end

  #
  # Check to see if this strategy exists (check by type)
  #
  def self.has_strategy?(name)
    @strategies.each { |s| return true if "#{s.metadata[:name]}" == "#{name}" }
  false
  end

end
end
