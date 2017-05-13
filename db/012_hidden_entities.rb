Sequel.migration do
  change do

    alter_table(:entities) do
      drop_column :prohibited
      add_column :hidden, FalseClass, :default=>false 
    end

  end
end
