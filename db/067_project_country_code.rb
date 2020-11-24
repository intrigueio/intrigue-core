Sequel.migration do
  change do

    alter_table(:projects) do
      add_column :country_code, String
    end

  end
end