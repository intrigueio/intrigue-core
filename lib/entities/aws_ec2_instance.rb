module Intrigue
  module Entity
  class AwsEc2Instance < Intrigue::Core::Model::Entity
  
    def self.metadata
      {
        name: 'AwsEc2Instance',
        description: 'An EC2 Instance',
        user_creatable: true,
        example: 'ec2-13-141-97-172.us-east-2.compute.amazonaws.com'
      }
    end

    def validate_entity
      # ec2 instances will always have a private DNS hostname e.g ip-172-31-25-112.us-east-1.compute.internal
      # however if an instance is launched into a private subnet, or is off (and isn't assigned an elastic ip) it will not have a public ip address or public hostname
      (name.match(/ec2-/) && name.match(/compute\.\.amazonaws\.com/)) || (name.match(/ip/) && name.match(/compute\.internal/))
    end

    def detail_string
      "EC2 Instance Details: #{details}"
    end

    def enrichment_tasks
      # todo
    end

    def scoped?(conditions={})
      return scoped unless scoped.nil?
      return true if self.allow_list || self.project.allow_list_entity?(self)
      return false if self.deny_list || self.project.deny_list_entity?(self)

    true # otherwise just default to true
    end

  end
  end
  end
