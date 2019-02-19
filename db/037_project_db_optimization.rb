Sequel.migration do
  change do

    alter_table(:projects) do
      add_index [:name]
    end

  end
end
