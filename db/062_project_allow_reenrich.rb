Sequel.migration do
  change do

    alter_table(:projects) do
      add_column :allow_reenrich, TrueClass, :default => false
    end

  end
end