module Intrigue
module Task
module Issue

  ###
  ### Helper method to create findings
  ###
  def _create_issue(details)
    # No need for a name in the hash now, remove it & pull out the name from the hash

    _notify("```Sev #{details[:severity]}! #{details[:name]}```") if details[:severity] <= 4
    
    hash = details.merge({ entity_id: @entity.id,
                           task_result_id: @task_result.id,
                           project_id: @project.id })

    _log_good "Creating issue with name: #{details[:name]}"
    issue = Intrigue::Model::Issue.create(_encode_hash(hash))
  end

end
end
end
