
class MissingTaskConfigurationError < StandardError

  def initialize(msg="Missing API Key, please check configuration!")
    super
  end

end