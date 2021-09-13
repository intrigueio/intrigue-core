class CoreApp < Sinatra::Base

  ###                      ###
  ### Analysis Views       ###
  ###                      ###

  get '/:project/issues' do

    (params[:page] != "" && params[:page].to_i > 0) ? @page = params[:page].to_i : @page = 1
    (params[:count] != "" && params[:count].to_i > 0) ? @count = params[:count].to_i : @count = 100

    issues = Intrigue::Core::Model::Issue.scope_by_project(@project_name)
    
    if params[:export] == "csv"

      content_type 'application/csv'
      attachment "#{@project_name}.csv"
      result = ""
      issues.each  { |i| result << "#{i.export_csv}\n" }
      return result

    elsif params[:export] == "json"

      content_type 'application/json'
      attachment "#{@project_name}.json"
      result = []
      issues.each  { |i| result << "#{i.export_json}" }
      return result.to_json

    else # normal page

     @issues = issues.paginate(@page, @count).order(:severity)
     erb :'issues/index'

    end

   end

   get "/:project/issues/:id.json" do
    content_type 'application/json'
    @issue = Intrigue::Core::Model::Issue.scope_by_project(@project_name).first(:id => params[:id].to_i)
    attachment "#{@project_name}_#{@issue.id}.json"
    @issue.export_json
  end
  
   get '/:project/issues/:id' do
    @issue = Intrigue::Core::Model::Issue.scope_by_project(@project_name).first(:id => params[:id].to_i)
    erb :'issues/detail'
  end

  

end
