Sequel.migration do
  change do

    alter_table(:entities) do
      add_column :details_raw, String, :text => true
    end

  end
end
