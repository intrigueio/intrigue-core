
class MissingTaskConfigurationError < StandardError
  def initialize(msg="Missing API key, please check configuration")
    super
  end
end

class InvalidTaskConfigurationError < StandardError
  def initialize(msg="Invalid API key, please check configuration")
    super
  end
end

class InvalidEntityError < StandardError
  def initialize(msg="Invalid dntity attempted")
    super
  end
end