module Intrigue
module Entity
class AwsS3Bucket < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "AwsS3Bucket",
      description: "An S3 Bucket",
      user_creatable: true,
      example: "bucket-name"
    }
  end

  def validate_entity
    s3_regex = /(?=^.{3,63}$)(?!^(\d+\.)+\d+$)(^(([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])$)/
    name.match(s3_regex)
  end

  def detail_string
    "File count: #{details["contents"].count}" if details["contents"]
  end

  def enrichment_tasks
    ['tasks/aws_s3_find_public_objects']
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
