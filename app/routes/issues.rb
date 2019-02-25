class IntrigueApp < Sinatra::Base

  ###                      ###
  ### Analysis Views       ###
  ###                      ###

  get '/:project/issues' do
    @issues = Intrigue::Model::Issue.scope_by_project(@project_name)
    erb :'issues/index'
  end

  get '/:project/issues/:id' do
    @issue = Intrigue::Model::Issue.scope_by_project(@project_name).first(:id => params[:id].to_i)
    erb :'issues/detail'
  end

end
