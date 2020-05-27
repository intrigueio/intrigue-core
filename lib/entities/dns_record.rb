module Intrigue
module Entity
class DnsRecord < Intrigue::Model::Entity
  
  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "DnsRecord",
      :description => "A Dns Record",
      :user_creatable => true,
      :example => "test.intrigue.io"
    }
  end

  def validate_entity
    name =~ dns_regex
  end

  def detail_string
    return "" unless details["resolutions"]
    details["resolutions"].each.group_by{|k| k["response_type"] }.map{|k,v| "#{k}: #{v.length}"}.join("| ")
  end

  def enrichment_tasks
    ["enrich/dns_record"]
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if self.seed
    return false if self.hidden # hit our blacklist so definitely false

    self.project.seeds.each do |s|
      return true if self.name =~ /[\.\s\@]#{Regexp.escape(s.name)}/i
    end

    # check hidden on-demand
    return false unless self.project.traversable_entity?(parse_domain_name(self.name), "Domain")

  # if we didnt match the above and we were asked, default to true
  true
  end

end
end
end
