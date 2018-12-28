Sequel.migration do
  change do

    alter_table(:projects) do
      add_column :cancelled, FalseClass, :default=>false
    end

  end
end
