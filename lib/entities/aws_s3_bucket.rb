module Intrigue
module Entity
class AwsS3Bucket < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "AwsS3Bucket",
      :description => "An S3 Bucket"
    }
  end

  def validate_entity
    name =~ /s3.amazonaws.com/
  end

end
end
end
