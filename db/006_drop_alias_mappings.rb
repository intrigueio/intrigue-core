Sequel.migration do
  change do


    drop_table :alias_mappings

    #alter_table :entities do
    #  String :aliases, :text => true
    #end

  end
end
