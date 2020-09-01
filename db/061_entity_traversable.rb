Sequel.migration do
  change do

    alter_table(:entities) do
      add_column :traversable, TrueClass
    end

  end
end