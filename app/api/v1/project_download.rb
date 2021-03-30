
class CoreApp < Sinatra::Base

  get "/api/v1/:project_name/download/entities/csv" do
    content_type 'application/csv'

    halt_unless_authenticated!

    @project_name = @params[:project_name]
    headers['Content-Disposition'] = "attachment;filename=#{@project_name.gsub(/\W/,"")}.entities.csv"

    @project = Intrigue::Core::Model::Project.first(name: @project_name)

    wrapped_api_response nil, @project.export_entities_csv
  end

  get "/api/v1/:project_name/download/issues/csv" do
    content_type 'application/csv'

    halt_unless_authenticated!

    @project_name = @params[:project_name]
    headers['Content-Disposition'] = "attachment;filename=#{@project_name.gsub(/\W/,"")}.issues.csv"

    @project = Intrigue::Core::Model::Project.first(name: @project_name)
    wrapped_api_response nil, @project.export_issues_csv
  end


  get "/api/v1/:project_name/download/json" do
    content_type 'application/json'

    halt_unless_authenticated!

    @project_name = @params[:project_name]
    headers['Content-Disposition'] = "attachment;filename=#{@project_name.gsub(/\W/,"")}.json"

    @project = Intrigue::Core::Model::Project.first(name: @project_name)
    wrapped_api_response nil, @project.export_json
  end

end