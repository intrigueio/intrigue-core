class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    post '/entities' do
      if params[:entity_type]
        entity_type = eval "Intrigue::Entity::#{params[:entity_type]}"
        @entities = Intrigue::Model::Entity.current_project.all(:type.like => entity_type).page(params[:page], :per_page => 100)
      elsif params[:entity_name]
        entity_name = params[:entity_name]
        @entities = Intrigue::Model::Entity.current_project.all(:name.like => "%#{entity_name}%").page(params[:page], :per_page => 100)
      else
        @entities = Intrigue::Model::Entity.current_project.page(params[:page], :per_page => 100)
      end
      erb :'entities/index'
    end

    get '/entities' do
      @entities = Intrigue::Model::Entity.current_project.page(params[:page], :per_page => 100)
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
