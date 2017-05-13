Sequel.migration do
  change do

    create_table :exports do
      primary_key :id
      foreign_key :project_id, :null => false
      String :type
      String :name, :size => 400
      String :contents, :text => true
      FalseClass :deleted, :default => false
    end

  end
end
