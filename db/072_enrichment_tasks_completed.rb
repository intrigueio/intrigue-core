Sequel.migration do
  change do

    alter_table :entities do
      add_column :enrichment_tasks_completed, String, :default => '[]', :text => true
    end

  end
end