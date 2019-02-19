Sequel.migration do
  change do

    alter_table(:entities) do
      add_index [:type,:id]
    end

  end
end
