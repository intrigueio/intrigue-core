Sequel.migration do
  change do

    alter_table :loggers do
      add_column :location, String
    end

  end
end
