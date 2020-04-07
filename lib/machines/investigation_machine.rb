module Intrigue
module Machine
class RunInvestigationTask < Intrigue::Machine::Base

    def self.metadata
      {
        :name => "run_investigation_task",
        :pretty_name => "Investigation Machine",
        :passive => false,
        :user_selectable => true,
        :authors => ["Anas Ben Salah"],
        :description => "This machine is for investigation purpose."
      }
    end

    # Recurse should receive a fully enriched object from the creator task
    def self.recurse(entity, task_result)

      project = entity.project
      seed_list = project.seeds.map{|s| s.name }.join(",")


      if entity.type_string == "IpAddress"

        # Search Apility API for IP address and domain reputation
        start_recursive_task(task_result,"threat/search_apility", entity)

        # Test any domain against more then 100 black lists
        start_recursive_task(task_result,"threat/search_blcheck_list", entity)

        # Looks up whether hosts are blocked by Cleanbrowsing.org DNS
        start_recursive_task(task_result,"threat/search_cleanbrowsing_dns", entity)

        # looks up whether hosts are blocked byCleanbrowsing.org DNS
        start_recursive_task(task_result,"threat/search_comodo_dns", entity)

        # Search Emerging Threats blacklist for listed IP address
        start_recursive_task(task_result,"threat/search_emerging_threats", entity)

        # This task hits FraudGuard api for ip reputation
        start_recursive_task(task_result,"threat/search_fraudguard", entity)

        # Looks up whether hosts are blocked by OpenDNS
        start_recursive_task(task_result,"threat/search_opendns", entity)

        # Looks up whether hosts are blocked by Quad9 DNS
        start_recursive_task(task_result,"threat/search_quad9_dns", entity)

        # Checks IPs vs Talos IP BlackList for threat data
        start_recursive_task(task_result,"search_talos_blacklist", entity)

        # Looks up whether hosts are blocked by Yandex DNS
        start_recursive_task(task_result,"threat/search_yandex_dns", entity)

        # This task searches AlienVault OTX via API and checks for related Hostnames, IpAddresses
        start_recursive_task(task_result,"threat/search_alienvault_otx", entity)

        # This task hits the BinaryEdge API and provides a risk score detail for a given IPAddress.
        # start_recursive_task(task_result,"search_binaryedge_risk_score", entity)

        # This task hits the BinaryEdge API for a given IP, and tells us if the address has seen activity consistent with torrenting
        start_recursive_task(task_result,"search_binaryedge_torrents", entity)

        # This task hits the Dehashed for leaked accounts
        #start_recursive_task(task_result,"search_dehashed", entity)



      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end
    end


end
end
end
