module Intrigue
module Task
class NetBlockExpand < BaseTask

  def self.metadata
    {
      :name => "net_block_expand",
      :pretty_name => "NetBlock Expand",
      :authors => ["jcran"],
      :description => "This task expands a NetBlock into a list of IP Addresses.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["NetBlock"],
      :example_entities => [ {"type" => "NetBlock", "details" => {"name" => "10.0.0.0/24"}} ],
      :allowed_options => [
        {:name => "threads", :regex => "integer", :default => 1 }
      ],
      :created_types => ["IpAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    opt_threads = _get_option("threads").to_i || 1

    begin
      netblock = IPAddr.new(_get_entity_name)
    rescue IPAddr::InvalidPrefixError => e
      _log_error "Invalid NetBlock!"
    end

    _log "Expanding Range: #{netblock}"

    # Use a thread pool to expand. Faster++
    work_q = Queue.new
    netblock.to_range.to_a[1..-1].each{|x| work_q.push x }
    workers = (0...opt_threads).map do
      Thread.new do
        begin
          while x = work_q.pop(true)
            _create_entity("IpAddress", {
              "name" => "#{x}",
              "provider" => "#{@entity.get_detail("organization_name")}"
            })
          end
        rescue ThreadError
        end
      end
    end; "ok"
    workers.map(&:join); "ok"

  end

end
end
end
