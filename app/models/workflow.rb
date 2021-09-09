module Intrigue
module Core
module Model
class Workflow < Sequel::Model

  plugin :timestamps
  plugin :serialization, :json, :definition
  plugin :validation_helpers

  def validate
    super
    validates_unique([:name])
  end

  ###
  ### Assumes we're handed a hash, and creates/stores the template
  ###
  def self.add_user_workflow(template)

    # create a worfklow from the template, note that symbolize only gets the
    # top level hash keys
    t = template.symbolize_keys!

    # Also save it in the database
    begin
      w = Intrigue::Core::Model::Workflow.update_or_create(t.except(:definition))
      w.definition = t[:definition]
      w.save_changes
    rescue Sequel::ValidationFailed => e
      return nil
    end

  end

  def to_h
    {
      name: name,
      pretty_name: pretty_name,
      user_selectable: user_selectable,
      maintainer: maintainer,
      description: description,
      flow: flow,
      definition: definition
    }
  end


end
end
end
end