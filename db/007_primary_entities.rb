Sequel.migration do
  change do

    create_table :alias_mappings do
      primary_key :id
      Integer :source_id
      Integer :target_id
    end

  end
end
