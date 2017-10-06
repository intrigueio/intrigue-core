Sequel.migration do
  change do

    alter_table(:entities) do
      add_index :id
    end

  end

end
