Sequel.migration do

  change do

    drop_table :findings
  
    create_table :issues do
      primary_key :id
      foreign_key :project_id, :null => false
      foreign_key :entity_id, :null => false
      foreign_key :task_result_id, :null => false

      String  :name, :size => 800
      String  :type
      Integer :severity
      String  :description, :text => true
      String  :status, :size => 80
      String  :details, :text => true
    end
  end

end

