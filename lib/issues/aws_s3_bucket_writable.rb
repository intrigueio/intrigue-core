
module Intrigue
module Issue
class AwsS3BucketWriteable < BaseIssue

  def self.generate(instance_details={})
    
    to_return = {
      added: "2020-01-01",
      name: "aws_s3_bucket_writable",
      pretty_name: "World Writeable AWS S3 Bucket",
      severity: 2,
      status: "confirmed",
      category: "misconfiguration",
      description: "A world writable AWS S3 bucket was discovered.",
      remediation: "Investigate whether this bucket should be writable, and if not, adjust the settings",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intels
        { type: "description", uri: "https://aws.amazon.com/premiumsupport/knowledge-center/secure-s3-resources/" },
        { type: "description", uri: "https://blog.detectify.com/2017/07/13/aws-s3-misconfiguration-explained-fix/" },
        { type: "remediation", uri: "https://auth0.com/blog/fantastic-public-s3-buckets-and-how-to-find-them/" },
        { type: "remediation", uri: "https://aws.amazon.com/s3/features/block-public-access/" }
      ]
    }.merge(instance_details)
  
    to_return[:severity] = 1 if instance_details[:public]
  
  to_return
  end

end
end
end
