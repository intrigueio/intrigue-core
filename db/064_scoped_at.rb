Sequel.migration do
  change do

    alter_table(:entities) do
      add_column :scoped_at, DateTime
    end

  end
end