
  # Export All Tasks
  get '/tasks.json' do
    tasks = []
    TaskFactory.list.each do |t|
        tasks << t.send(:new).metadata
    end
  tasks.to_json
  end

  # Export a single task
  get '/tasks/:id.json' do
    task_name = params[:id]
  TaskFactory.create_by_name(task_name).metadata.to_json
  end
