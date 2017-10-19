class IntrigueApp < Sinatra::Base
  #include Intrigue::Task::Helper

    get '/:project/signals' do

      @signals = Intrigue::Model::Signal.scope_by_project(@project_name)

    erb :'signals/index'
    end


    get '/:project/signals/generate' do

      Intrigue::SignalFactory.all.each {|x| x.generate }

    erb :'signals/index'
    end


end
