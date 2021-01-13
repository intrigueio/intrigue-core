module Intrigue
    module Task
    class JarmHashCalculator < BaseTask
    
      def self.metadata
        {
          :name => "jarm_hash_calculator",
          :pretty_name => "Jarm Hash Calculator",
          :authors => ["shpendk"],
          :description => "This task calculates the jarm hash for an entity.",
          :references => [],
          :type => "discovery",
          :passive => false,
          :allowed_types => ["Uri","NetworkService"],
          :example_entities => [
            {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
          ],
          :allowed_options => [],
          :created_types => []
        }
      end
    
      ## Default method, subclasses must override this
      def run
        super
        name = _get_entity_name
        type = _get_entity_type_string

        _log "Attempting to calculate Jarm hash for #{name}"

        # scan via jarm
        if type == "Uri"
            jarm_res = _unsafe_system "jarmscan #{name}", 60
        elsif type == "NetworkService"
            port = _get_entity_detail("port")
            ip_address = _get_entity_detail("ip_address")
            jarm_res = _unsafe_system "jarmscan -p #{port} #{ip_address}", 60
        else
            _log_error "Entity type not supported"
            return
        end

        # extract hash
        jarm_parts = jarm_res.split("\t")
        if jarm_parts[2]
            jarm_hash = jarm_parts[2].delete!("\n")
        end

        # attach hash to entity
        if jarm_hash && jarm_hash != "" && !(jarm_hash =~ /^0+$/)
            _set_entity_detail "jarm_hash", jarm_hash
        end

      end
    
    end
    end
    end
    