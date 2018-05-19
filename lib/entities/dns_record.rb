module Intrigue
module Entity
class DnsRecord < Intrigue::Model::Entity
  include Intrigue::Task::Helper

  def self.metadata
    {
      :name => "DnsRecord",
      :description => "A Dns Record",
      :user_creatable => true
    }
  end

  def validate_entity
    name =~ /\w.*/ #_dns_regex
  end

  def primary
    false
  end

  def detail_string
    return "" unless details["dns_entries"]
    details["dns_entries"].each.group_by{|k| k["response_type"] }.map{|k,v| "#{k}: #{v.length}"}.join("| ")
  end

  def enrichment_tasks
    ["enrich/dns_record"]
  end

end
end
end
