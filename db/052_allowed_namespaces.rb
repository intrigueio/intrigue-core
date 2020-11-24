Sequel.migration do
  change do

    alter_table(:projects) do
      set_column_default :allowed_namespaces, "[]"
    end

  end
end

    
