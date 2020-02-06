Sequel.migration do
  change do

    alter_table(:issues) do
      add_column :source, String # adds an optional source for issues that require it
    end

  end
end
