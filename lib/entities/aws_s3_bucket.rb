module Intrigue
module Entity
class AwsS3Bucket < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "AwsS3Bucket",
      description: "An S3 Bucket",
      user_creatable: true,
      example: "http://s3.amazonaws.com/bucket/"
    }
  end

  def validate_entity
    name.match(/s3/) && name.match(/\.amazonaws\.com/)
  end

  def detail_string
    "File count: #{details["contents"].count}" if details["contents"]
  end

  def enrichment_tasks
    ["enrich/aws_s3_bucket"]
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
