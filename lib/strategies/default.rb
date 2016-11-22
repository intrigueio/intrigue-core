module Intrigue
module Strategy
  class Default < Intrigue::Strategy::Base

    def self.start(entity, task_result)
      puts "Start called for #{entity} with result #{task_result}"

      if task_result.depth == 0
        puts "Start called for #{entity} with result #{task_result} but at max depth. Returning!"
        return
      end

      start_recursive_task(task_result, "example", entity)
    end

  end
end
end
