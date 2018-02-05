Sequel.migration do
  change do

    alter_table(:entities) do
      add_index [:project_id, :type]
      add_index [:project_id, :alias_group_id]
    end

    alter_table(:alias_groups) do
      add_index :project_id
    end

  end
end
