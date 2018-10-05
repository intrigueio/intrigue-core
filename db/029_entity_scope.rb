Sequel.migration do
  change do

    alter_table(:entities) do
      add_column :scoped, FalseClass, :default=>false
    end

  end
end
