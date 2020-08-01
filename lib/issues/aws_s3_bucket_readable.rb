
module Intrigue
module Issue
class AwsS3BucketReadable < BaseIssue

  def self.generate(instance_details={})
    
    to_return = {
      added: "2020-01-01",
      name: "aws_s3_bucket_readable",
      pretty_name: "World Readable AWS S3 Bucket",
      severity: 4,
      status: "confirmed",
      category: "application",
      description: "A world readable AWS S3 bucket was found at #{instance_details[:uri]}.",
      remediation: "Investigate whether this bucket should be readable, and if not, adjust the settings",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://aws.amazon.com/premiumsupport/knowledge-center/secure-s3-resources/" },
        { type: "description", uri: "https://blog.detectify.com/2017/07/13/aws-s3-misconfiguration-explained-fix/" },
        { type: "remediation", uri: "https://auth0.com/blog/fantastic-public-s3-buckets-and-how-to-find-them/" },
        { type: "remediation", uri: "https://aws.amazon.com/s3/features/block-public-access/" }
      ]
    }.merge(instance_details)
  
  to_return
  end

end
end
end
