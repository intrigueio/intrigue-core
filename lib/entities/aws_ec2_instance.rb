module Intrigue
  module Entity
  class AwsEC2Instance < Intrigue::Core::Model::Entity
  
    # the sole purpose behind this entity's creation is that ec2 instances will always have a private hostname/ip address but not a public one
    # this can be in scenarios such as the ec2 instance being stopped (without having an elastic ip associated to it) or where the instance is in a private subnet

    def self.metadata
      {
        name: "AwsEC2Instance",
        description: "An AWS EC2 Instance",
        user_creatable: true,
        example: "ec2-13-132-97-113.us-east-2.compute.amazonaws.com"
      }
    end

    def validate_entity
      # validate either public ipv4 hostname or private ipv4 hostname
      (name.match(/ec2/) && name.match(/\.amazonaws\.com/)) || (name.match(/ip/) && name.match(/\.internal/))
    end

    def detail_string
      "AWS EC2 Instance: #{details}"
    end

    def enrichment_tasks
      ["enrich/aws_ec2_instance"]
    end

    def scoped?
      return scoped unless scoped.nil?
      return true if self.allow_list || self.project.allow_list_entity?(self)
      return false if self.deny_list || self.project.deny_list_entity?(self)
    true # otherwise just default to true
    end

  end
  end
  end
  