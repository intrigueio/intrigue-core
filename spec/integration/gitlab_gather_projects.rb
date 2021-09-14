require_relative '../spec_helper'

def _start_task_helper(gitlab_project_uri)
  project = Intrigue::Core::Model::Project.find_or_create(name: 'rspectesting-project')
  entity = { 'type' => 'GitlabAccount', 'details' => { 'name' => gitlab_project_uri } }
  created_entity = Intrigue::EntityManager.create_first_entity(
    'rspectesting-project', entity['type'], entity['details']['name'], entity['details'], entity['sensitive_details']
  )
  task = start_task('task', project, nil, 'gather_gitlab_projects', created_entity, 1, [{}], [], nil, false, false)
  check_task_result = ->(task_id) { Intrigue::Core::Model::TaskResult.scope_by_project(project.name).first(id: task_id) }
  until check_task_result.call(task.values[:id]).values[:complete]
    p 'waiting for task to complete'
    sleep 5
  end
  # return result
  JSON.parse(check_task_result.call(task.values[:id]).export_json)
end

describe 'it runs the gather_gitlab_projects task' do
  it 'should return nothing as account does not exist on gitlab.com' do
    task_result = _start_task_helper('https://gitlab.com/adfslkajsdflkajsdflaksdfj')
    expect(task_result['entities'].size).to eql(0)
  end

  it 'should return nothing as account does not exist on gitlab self-hosted' do
    task_result = _start_task_helper('https://gitlab.gnome.org/alkdfjaldfkalsdfkjasf')
    expect(task_result['entities'].size).to eql(0)
  end

  it 'should return 3 repositories belonging to account on gitlab.com' do
    task_result = _start_task_helper('https://gitlab.com/maxim.123')
    expect(task_result['entities'].size).to eql(3)
  end

  it 'should return 1 repositories belonging to project on gitlab.com' do
    task_result = _start_task_helper('https://gitlab.com/pikachugrouprocks/pokemonrules/charizardpwns')
    expect(task_result['entities'].size).to eql(1)
  end

  it 'should return 1 repositories belonging to account on gitlab self-hosted' do
    task_result = _start_task_helper('https://gitlab.gnome.org/mikeh1')
    expect(task_result['entities'].size).to eql(1)
  end

  # cant include authenticated tests or token leaked
end
