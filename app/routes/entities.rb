class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    get '/entities' do
      if params[:type]
        entity_type = eval "Intrigue::Entity::#{params[:type]}"
        @entities = Intrigue::Model::Entity.current_project.all(:type.like => entity_type).page(params[:page], :per_page => 100)
      else
        @entities = Intrigue::Model::Entity.current_project.page(params[:page], :per_page => 100)
      end
      erb :'entities/index'
    end

   get '/entities/:id' do
      @entity = Intrigue::Model::Entity.current_project.all(:id => params[:id]).first

      @tasks = Intrigue::TaskFactory.list.map{|x| x.send(:new)}
      @task_names = @tasks.map{|t| t.metadata[:pretty_name]}.sort

      erb :'entities/detail'
    end

  end
end
