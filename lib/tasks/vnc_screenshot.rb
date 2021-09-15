module Intrigue
  module Task
    class VncScreenshot < BaseTask
      def self.metadata
        {
          name: 'vnc_screenshot',
          pretty_name: 'Screenshot VNC Session',
          authors: ['duarte'],
          description: 'This task performs a screenshot of an VNC session',
          type: 'discovery',
          passive: false,
          allowed_types: ['NetworkService'],
          example_entities: [{ 'type' => 'NetworkService', 'details' => { 'name' => '127.0.0.1:5900/tcp' } }],
          allowed_options: [],
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        net_service = _get_entity_name

        target = net_service.split(':').first

        port = net_service.split(':').last.split('/').first

        unless port.to_i.between?(5900,5999)
          _log 'Incorrect VNC port! Will not perform certificate extraction.'
          return
        end

        rdesktop_command = "xvfb-run scrying -t vnc://#{target} -o /tmp/scrying_outputs"
        _log "Running: #{rdesktop_command}"
        _unsafe_system(rdesktop_command)

        if File.file?("/tmp/scrying_outputs/vnc/#{target}-#{port}.png")
          
          _log 'Found screenshot! Attaching to entity as detail'
          # todo, set image as entity detail
          screenshot_image = Base64.strict_encode64(File.read("/tmp/scrying_outputs/vnc/#{target}-#{port}.png"))
          _set_entity_detail 'extended_screenshot_contents', screenshot_image
          _set_entity_detail 'screenshot_exists', true

          # delete temporary screenshot file
          File.delete("/tmp/scrying_outputs/vnc/#{target}-#{port}.png")
        else
          _set_entity_detail 'screenshot_exists', false
        end
      end
    end
  end
end
