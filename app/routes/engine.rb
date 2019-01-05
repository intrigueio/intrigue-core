class IntrigueApp < Sinatra::Base

    ###
    ### status
    ###
    get "/engine/?" do
      content_type "application/json"

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

    output.to_json
    end

end