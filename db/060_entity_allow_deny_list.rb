Sequel.migration do
  change do

    alter_table(:entities) do
      add_column :allow_list, TrueClass
      add_column :deny_list, TrueClass
    end

  end
end