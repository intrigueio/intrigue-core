Sequel.migration do
  change do

    create_table :workflows do
      primary_key :id
      Integer :default_depth, :default => 5
      String :type, :size => 40, :default => "recursive"
      String :name, :size => 400
      String :pretty_name, :size => 400
      String :maintainer, :size => 400
      FalseClass :user_selectable, :default => true
      FalseClass :deleted, :default => false
      String :description
      String :definition, :text => true
    end

  end
end