Sequel.migration do
    change do
  
      alter_table :issues do
        add_index [:project_id, :entity_id, :name, :source], :unique => true  
      end
  
    end
  end