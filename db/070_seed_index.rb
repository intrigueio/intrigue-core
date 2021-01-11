Sequel.migration do
  change do

    alter_table :entities do
      add_index [:project_id, :entity_id, :seed]
    end
    
  end
end