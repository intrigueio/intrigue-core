class IntrigueApp < Sinatra::Base

  ###
  ### status
  ###
  get "/engine/?" do

    sidekiq_stats = Sidekiq::Stats.new
    project_listing = Intrigue::Model::Project.all.map { |p|
        { :name => "#{p.name}", :entities => "#{p.entities.count}" } }

    output = {
      :version => IntrigueApp.version,
      :projects => project_listing,
      :tasks => {
        :processed => sidekiq_stats.processed,
        :failed => sidekiq_stats.failed,
        :queued => sidekiq_stats.queues
      }
    }

  headers 'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Methods' => ['OPTIONS','GET']

  content_type "application/json"
  output.to_json
  end

end