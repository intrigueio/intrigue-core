Sequel.migration do
  change do

    alter_table(:projects) do
      set_column_default :additional_exception_list, "[]"
    end

  end
end