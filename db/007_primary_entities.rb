Sequel.migration do
  change do

    create_table :alias_mappings do
      primary_key :id
      Integer :source_id
      Integer :target_id
    end

    #alter_table :entities do
    #  add_column :primary, FalseClass, default: true
    #end

  end
end
