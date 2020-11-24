Sequel.migration do
  change do

    alter_table(:global_entities) do
      add_index [:name, :type]
    end

  end
end