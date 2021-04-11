Sequel.migration do
  change do

    alter_table :entities do
      set_column_default(:scoped, nil)
    end

    alter_table :issues do
      set_column_default(:scoped, nil)
    end

  end
end