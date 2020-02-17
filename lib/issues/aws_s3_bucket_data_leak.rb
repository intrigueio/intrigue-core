
module Intrigue
module Issue
class AwsS3BucketDataLeak < BaseIssue

  def self.generate(instance_details={})

    to_return = {
      name: "aws_s3_bucket_data_leak",
      pretty_name: "S3 Bucket Data Leak",
      severity: 2,
      status: "confirmed",
      category: "application",
      description: "Interesting files located in an S3 bucket.",
      remediation: "Investigate whether those files should be exposed, and if not, adjust the settings to Private S3 Bucket",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        "https://aws.amazon.com/fr/blogs/security/how-to-use-bucket-policies-and-apply-defense-in-depth-to-help-secure-your-amazon-s3-data/"
      ]
    }.merge(instance_details)

  to_return
  end

end
end
end
