module Intrigue
module Strategy
  class ScanCriticals < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "scan_criticals",
        :pretty_name => "scan_criticals",
        :passive => false,
        :authors => ["jcran"],
        :description => "This strategy runs a series of scans against every netblock, looking for critical issues."
      }
    end

    def self.recurse(entity, task_result)
      if entity.type_string == "NetBlock"
        start_recursive_task(task_result,"cisco_smart_install_scan",entity,[
            {"name" => "max_rate", "value" => 10000 }])
      end
    end

end
end
end
