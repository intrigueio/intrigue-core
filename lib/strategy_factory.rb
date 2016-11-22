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
    available_strategies
  end

  private

  def self.available_strategies
    @strategies
  end

end
end
