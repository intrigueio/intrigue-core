module Intrigue
module Task
module Finding

  ###
  ### Helper method to create findings
  ###
  def _create_finding(finding_details)
    # No need for a name in the hash now, remove it & pull out the name from the hash

    # check and make sure we're allowed to create findings
    # TODO
    
    hash = finding_details.merge({ entity_id: @entity.id,
                                   task_result_id: @task_result.id,
                                   project_id: @project.id })

    _log_good "creating finding with attributes: #{finding_details}"

    finding = Intrigue::Model::Finding.create(hash)
  end

=begin
# create a finding
include Intrigue::Task::Finding
domain_name = "test"
nameserver = "whatever"
zone = [1,2,3,4]
_create_finding({
  name: "AXFR enabled on #{domain_name} using #{nameserver}",
  type: "dns_zone_transfer",
  severity: 4,
  status: "potential",
  description: "Zone transfer on #{domain_name} using #{nameserver} resulted in leak of #{zone.count} records.",
  details: { records: zone.map{|r| r.to_s } }
})
=end


=begin
name: name,
description: desc,
type: type_string,
status: status,
details: details,
entity_id: @entity.id,
project_id: task_result.project.id,
task_result_id: task_result.id
=end




end
end
end
