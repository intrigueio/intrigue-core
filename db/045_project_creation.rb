Sequel.migration do
  change do

    alter_table(:projects) do
      add_column :created_at, DateTime, default: Sequel::CURRENT_TIMESTAMP
    end

  end
end
