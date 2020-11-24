Sequel.migration do
  change do

    alter_table(:projects) do
      add_column :created_at, DateTime
    end

  end
end
