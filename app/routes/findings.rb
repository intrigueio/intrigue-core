class IntrigueApp < Sinatra::Base
  #include Intrigue::Task::Helper
  namespace '/v1' do

    get '/:project/findings' do

      @findings = Intrigue::Model::Finding.scope_by_project(@project_name)

    erb :'findings/index'
    end


  end
end
