Sequel.migration do
  change do

    drop_table :findings

    create_table :signals do
      primary_key :id
      foreign_key :project_id, :null => false
      String :type
      Integer :severity
      String :name, :size => 800
      String :details, :text => true
      FalseClass :resolved, :default => false
      FalseClass :deleted, :default => false
    end

    create_table :signals_entities do
      primary_key :id
      Integer :entity_id
      Integer :signal_id      
    end

  end

end
