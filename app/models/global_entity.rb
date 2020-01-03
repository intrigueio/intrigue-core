module Intrigue
  module Model
    class GlobalEntity < Sequel::Model
      plugin :validation_helpers

      self.raise_on_save_failure = false

      def validate
        super
        validates_unique([:namespace, :type, :name])
      end

      #TODO .. this method should only be called if we don't already have the entity in our project
      def self.traversable?(entity_type, entity_name, project)
         
        out = false 

        # otherwise first check to see if we know about this exact entity 
        global_entity = Intrigue::Model::GlobalEntity.first(:name => entity_name, :type => entity_type)

        # Okay we know it iexsts, is it in our project (good) or someone else (no traverse!)
        if global_entity && !project.allowed_namespaces.empty?
          puts "Got an exact match"
          project.allowed_namespaces.each do |namespace|
            puts "Checking: #{global_entity.namespace.downcase} == #{namespace.downcase}"
            if global_entity.namespace.downcase == namespace.downcase # Good! 
              return true # we can immediately return 
            else 
              out = false # but continue on
            end
          end
        end

        ### Otherwise, the harder case... we need to find if it matches any existing entity 
        # take the example case of https://google.com

        # TODAY this only works on domains... and things that have a domain (like a uri)

        # then check each for a match 
        puts "Checking for a fuzzy match"
        found_it = false
        Intrigue::Model::GlobalEntity.where(:type => "Domain").all.each do |ge|
          # this needs a couple (3) cases:
          # 1) case where we're an EXACT match (ey.com)
          # 2) case where we're a subdomain of an exception domain (x.ey.com)
          # 3) case where we're a uri and should match an exception domain (https://ey.com)
          # none of these cases should match the case: jcpenney.com
          if (entity_name.downcase =~ /^#{Regexp.escape(ge.name.downcase)}(:[0-9]*)?$/ ||
            entity_name.downcase =~ /^.*\.#{Regexp.escape(ge.name.downcase)}(:[0-9]*)?$/ ||
            entity_name.downcase =~ /^https?:\/\/#{Regexp.escape(ge.name.downcase)}(:[0-9]*)?$/)
            
            puts "Got a fuzzy match"

            #okay we found it... now we need to check if it's an allowed project
            found_it  = true

            # now lets check if we have an allowance for it
            (project.allowed_namespaces || []).each do |namespace|
              puts "Checking: #{ge.namespace.downcase} == #{namespace.downcase}"
              if ge.namespace.downcase == namespace.downcase # Good! 
                puts "Got it! "
                return true 
              end
            end
          end
        end


      if found_it 
        puts "We found it but it belonged to someone else"
        out = false 
      else
        puts "We never found it!"
        out = true 
      end

      puts "Result for: #{entity_type} #{entity_name} in project #{project.name}: #{out}" 

      out 
      end

      def self.load_global_namespace(api_key)
        data = JSON.parse(RestClient.get("https://app.intrigue.io/api/global/entities?key=#{api_key}"))
        (data["entities"] || []).each do |x|
          Intrigue::Model::GlobalEntity.create(:name => x["name"], :type => x["type"], :namespace => x["namespace"])
        end
      end

=begin
      def self.add_list(list)
      
          #{
          #  "namespace" => "intrigueio",
          #  "type" => "Intrigue::Entity::Domain",
          #  "name" => "intrigue/io",
          #}

          # Create a queue to hold our list of exceptions & enqueue
          work_q = Queue.new
          list.each do |s|
            work_q.push(s)
          end
      
          # Create a pool of worker threads to work on the queue
          max_threads = 1
          max_threads = 10 if list.count > 10000
          max_threads = 30 if list.count > 100000
      
          workers = (0...max_threads).map do
            Thread.new do
              _log "Starting thread to parse exception entities"
              begin
                while entity = work_q.pop(true) do
                  next unless entity # handle nil entries
                  Intrigue::Model::NoTraverseEntity.create(
                    :namespace => entity["namespace"], 
                    :name => entity["name"], 
                    :type => entity["type"])
                end
              rescue ThreadError
              end
            end
          end; "ok"
          workers.map(&:join); "ok"
        end
=end
    end
  end
end
