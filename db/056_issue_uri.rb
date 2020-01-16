Sequel.migration do
  change do

    alter_table(:issues) do
      add_column :uri, String
    end

  end
end
