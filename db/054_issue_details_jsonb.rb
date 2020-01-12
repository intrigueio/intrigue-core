Sequel.migration do
  change do

    alter_table(:issues) do
      drop_column :details
      add_column :details, :jsonb, {null: false, default: "{}" }
    end

  end
end
