Sequel.migration do
  change do

    alter_table(:issues) do
      add_column :pretty_name, String
    end

  end
end
