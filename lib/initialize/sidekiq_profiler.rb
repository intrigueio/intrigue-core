=begin
while true; do cat heap*.json | ruby -rjson -ne ' obj = JSON.parse($_).values_at("file","line","type"); puts obj.join(":") if obj.first ' | uniq -c   | sort -n   | tail -20; done
=end

if ENV["SIDEKIQ_PROFILE"]
  require "objspace"
  ObjectSpace.trace_object_allocations_start
  Sidekiq.logger.info "allocations tracing enabled"

  module Sidekiq
    module Middleware
      module Server
        class Profiler

          # Number of jobs to process before reporting
          JOBS = 100

          def self.dump_name
            @@dump_name
          end

          def self.dump_name=(d)
            @@dump_name = d
          end

          def self.counter
            @@counter
          end

          def self.counter=(c)
            @@counter = c
          end

          self.dump_name = "heap-#{rand(1000000)}.json"
          self.counter = 0

          def self.synchronize(&block)
            @lock ||= Mutex.new
            @lock.synchronize(&block)
          end

          def call(worker_instance, item, queue)
            begin
              yield
            ensure
              self.class.synchronize do
                self.class.counter += 1
                Sidekiq.logger.info "#{$0} #{self.class.counter} jobs"

                if self.class.counter % JOBS == 0
                  Sidekiq.logger.info "Reporting allocations after #{self.class.counter} jobs"
                  GC.start
                  f = File.open(self.class.dump_name, "w")
                  ObjectSpace.dump_all(output: f)
                  f.close
                  Sidekiq.logger.info "Heap saved to #{self.class.dump_name}"
                end
              end
            end
          end
        end
      end
    end
  end

  Sidekiq.configure_server do |config|
    config.server_middleware do |chain|
      chain.add Sidekiq::Middleware::Server::Profiler
    end
  end
end
