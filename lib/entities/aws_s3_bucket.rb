module Intrigue
module Entity
class AwsS3Bucket < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "AwsS3Bucket",
      :description => "An S3 Bucket",
      :user_creatable => true
    }
  end

  def validate_entity
    name =~ /s3.amazonaws.com/
  end

  def detail_string
    "File count: #{details["contents"].count}" if details["contents"]
  end

  def enrichment_tasks
    ["enrich/aws_s3_bucket"]
  end

end
end
end
