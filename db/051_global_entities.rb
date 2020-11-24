Sequel.migration do
  change do

    alter_table(:projects) do
      drop_column :additional_exception_list
      add_column :allowed_namespaces, String
    end

    create_table :global_entities do
      primary_key :id
      String :namespace, :null => false
      String :name, :size => 200, :null => false
      String :type, :size => 60, :null => false
      index :namespace
    end

  end
end