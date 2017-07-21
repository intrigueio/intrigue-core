Sequel.migration do
  change do

    create_table :alias_groups do
      primary_key :id
      foreign_key :project_id, :null => false
      String :name, :size => 800
    end

    alter_table(:entities) do
      add_foreign_key :alias_group_id, :alias_groups, :on_delete => :cascade
    end

    alter_table(:alias_mappings) do
      add_foreign_key :project_id, :projects, :on_delete => :cascade
    end

  end
end
