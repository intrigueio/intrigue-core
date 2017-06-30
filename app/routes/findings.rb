class IntrigueApp < Sinatra::Base
  #include Intrigue::Task::Helper
  namespace '/v1' do

    get '/:project/findings' do

      @findings = Intrigue::Model::Finding.all
      
    erb :'findings/index'
    end


  end
end
