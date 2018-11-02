Sequel.migration do
  change do

    alter_table(:projects) do
      add_column :seeds, String, :text => true
    end

  end
end
