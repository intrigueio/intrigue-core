Sequel.migration do
  change do

    alter_table(:issues) do
      add_column :references, String, :text => true
    end

  end
end
