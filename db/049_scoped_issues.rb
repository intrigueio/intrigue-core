Sequel.migration do
    change do
  
      alter_table(:issues) do
        add_column :scoped, TrueClass, :default => false
      end
  
    end
  end