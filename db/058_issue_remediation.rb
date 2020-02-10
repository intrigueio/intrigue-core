Sequel.migration do
  change do

    alter_table(:issues) do
      add_column :remediation, String # adds an optional source for issues that require it
    end

  end
end
