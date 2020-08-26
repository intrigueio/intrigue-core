module Intrigue
module Entity
class AwsS3Bucket < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "AwsS3Bucket",
      :description => "An S3 Bucket",
      :user_creatable => true,
      :example => "http://s3.amazonaws.com/bucket/"
    }
  end

  def validate_entity
    name =~ /s3/ && name =~ /.amazonaws.com/
  end

  def detail_string
    "File count: #{details["contents"].count}" if details["contents"]
  end

  def enrichment_tasks
    ["enrich/aws_s3_bucket"]
  end

  def scoped?(conditions={})
    return true if self.allow_list
    return false if self.deny_list
  true # otherwise just default to true
  end

end
end
end
