Sequel.migration do
  change do

    alter_table(:issues) do
      add_column :category, String
    end

  end
end