module Intrigue
    module Task
    class RdpScreenshot < BaseTask
    
      def self.metadata
        {
          :name => "rdp_screenshot",
          :pretty_name => "Screenshot RDP Session",
          :authors => ["shpendk"],
          :description => "This task performs a screenshot of an RDP session",
          :references => [],
          :type => "discovery",
          :passive => false,
          :allowed_types => ["NetworkService"],
          :example_entities => [{"type" => "NetworkService", "details" => {"name" => "127.0.0.1:3389/tcp"}},],
          :allowed_options => [],
          :created_types => []
        }
      end
  
      ## Default method, subclasses must override this
      def run
        super
  
        net_service = _get_entity_name
  
        target = net_service.split(":").first
        port = net_service.split(":").last.split("/").first
  
        unless port == "3389"
          _log "Incorrect RDP port! Will not perform certificate extraction."
          return
        end
        
        rdesktop_command = "xvfb-run scrying -t rdp://#{target} -o /tmp/scrying_outputs"
        _log "Running: #{rdesktop_command}"
        _unsafe_system(rdesktop_command)
        
        if File.file?("/tmp/scrying_outputs/rdp/#{target}-3389.png")
            _log "Found screenshot! Attaching to entity as detail"
            # todo, set image as entity detail
            screenshot_image = Base64.strict_encode64(File.read("/tmp/scrying_outputs/rdp/#{target}-3389.png"))
            _set_entity_detail "extended_screenshot_contents", screenshot_image
            _set_entity_detail "screenshot_exists", true

    
            # delete temporary screenshot file
            _unsafe_system("rm /tmp/scrying_outputs/rdp/#{target}-3389.png")
        else
          _set_entity_detail "screenshot_exists", false
        end

      end
    
    end
    end
    end
    