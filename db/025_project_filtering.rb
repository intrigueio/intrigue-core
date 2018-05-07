Sequel.migration do
  change do

    alter_table(:projects) do
      add_column :use_standard_exceptions, FalseClass, :default=>true
      add_column :additional_exception_list, String, :text => true, :default => ""
    end


  end
end
