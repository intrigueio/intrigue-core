
###
### This is a set of intrigue specific exceptions that may get thrown
###  ... particularly when a task fails. This gives us the ability to 
###  catch the error in a single place and route the error appropriately.
###

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
  def initialize(msg="Invalid entity attempted")
    super
  end
end

class SystemResourceMissing < StandardError
def initialize(msg="Missing system resource")
  super
end
end