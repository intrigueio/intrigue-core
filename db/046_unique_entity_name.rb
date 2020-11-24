Sequel.migration do
  change do

    alter_table(:entities) do
      drop_index [:project_id, :type, :name]
      drop_index [:project_id, :name]
      add_index [:project_id, :type, :name], :unique => true  
    end

  end
end
