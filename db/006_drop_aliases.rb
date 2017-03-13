Sequel.migration do
  change do

    #alter_table :entities do
    #  String :names, :text => true
    #end

    drop_table :alias_mappings

  end
end
