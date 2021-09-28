Sequel.migration do
  change do

   drop_table :task_results_scan_results

  end
end