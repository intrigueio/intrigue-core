Sequel.migration do
  change do

    alter_table :entities do
      add_column :sensitive_details, String, :default => '[]', :text => true
    end

  end
end