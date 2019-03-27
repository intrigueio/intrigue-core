module Intrigue
module Entity
class AwsRegion < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "AwsRegion",
      :description => "A specific AWS Region",
      :user_creatable => true
    }
  end

  def validate_entity
    [ "all",
      "us-east-1",
      "us-east-2",
      "us-east-1",
      "us-west-1",
      "us-west-2",
      "ap-south-1",
      "ap-northeast-3",
      "ap-northeast-2",
      "ap-southeast-1",
      "ap-southeast-2",
      "ap-northeast-1",
      "ca-central-1",
      "cn-north-1",
      "cn-northwest-1",
      "eu-central-1",
      "eu-west-1",
      "eu-west-2",
      "eu-west-3",
      "eu-north-1",
      "sa-east-1",
      "us-gov-east-1",
      "us-gov-west-1"].include? name
  end

  def enrichment_tasks
    ["enrich/generic"]
  end

end
end
end
