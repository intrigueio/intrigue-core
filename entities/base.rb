module Intrigue
module Entity
class Base

  attr_accessor :attributes

  def initialize
    @attributes = {}
  end

  def self.inherited(base)
    EntityFactory.register(base)
  end

  def set_attributes(attributes)
    return false unless validate(attributes)
    @attributes = attributes
  end

  def to_json
    {
      :type => metadata[:type],
      :attributes => @attributes
    }
  end

  def form
    output = ""
    output << "Type: <input type=\"text\" id=\"entity_type\" name=\"entity_type\" value=\"#{ _escape_html metadata[:type]}\"><br/>"
    output << "Name: <input type=\"text\" id=\"attrib_name\" name=\"attrib_name\" value=\"#{ _escape_html @attributes[:name]}\"><br/>"
  output
  end

  # override this method
  def metadata
    raise "Metadata method should be overridden"
  end

  # override this method
  def validate(attributes)
    raise "Validate method missing for #{self.type}"
  end

  private
  def _escape_html(text)
    Rack::Utils.escape_html(text)
  end
end
end
end
