Sequel.migration do
  change do

    alter_table(:projects) do
      add_column :uuid, String
    end

  end
end