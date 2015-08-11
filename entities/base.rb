module Intrigue
module Entity
class Base < Intrigue::Model::Entity

  def self.inherited(base)
    EntityFactory.register(base)
  end

  def set_attribute(key, value)
    @attributes[key.to_sym] = value
    return false unless validate(attributes)
  true
  end

  def set_attributes(attributes)
    return false unless validate(attributes)
    @attributes = attributes
  end

  #def to_json
  #  {
  #    :id => id,
  #    :type => metadata[:type],
  #    :attributes => @attributes
  #  }
  #end

  def form
    %{
    <div class="form-group">
      <label for="entity_type" class="col-xs-4 control-label">Type</label>
      <div class="col-xs-6">
        <input type="text" class="form-control input-sm" id="entity_type" name="entity_type" value="#{metadata[:type]}">
      </div>
    </div>
    <div class="form-group">
      <label for="attrib_name" class="col-xs-4 control-label">Name</label>
      <div class="col-xs-6">
        <input type="text" class="form-control input-sm" id="attrib_name" name="attrib_name" value="#{_escape_html @attributes[:name]}">
      </div>
    </div>
  }
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
    text
  end
end
end
end
