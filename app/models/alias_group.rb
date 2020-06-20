module Intrigue
module Core
module Model
  class AliasGroup < Sequel::Model
    plugin :timestamps

    one_to_many :entities
    many_to_one :project

    def self.scope_by_project(project_name)
      named_project = Intrigue::Core::Model::Project.first(:name => project_name)
      where(Sequel.&(:project => named_project))
    end

  end
end
end
end