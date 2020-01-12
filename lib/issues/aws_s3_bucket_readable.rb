
module Intrigue
module Issue
class AwsS3BucketReadable < BaseIssue

  def self.generate(instance_details={})
    
    to_return = {
      name: "aws_s3_bucket_readable",
      pretty_name: "Readable AWS S3 Bucket",
      severity: 3,
      status: "confirmed",
      category: "application",
      description: "A readable AWS S3 bucket was found at #{instance_details[:uri]}.",
      remediation: "Investigate whether this bucket should be readable, and if not, adjust the settings",
      references: [
        { type: "vulnerability", uri: "https://aws.amazon.com/premiumsupport/knowledge-center/secure-s3-resources/" },
        { type: "vulnerability", uri: "https://blog.detectify.com/2017/07/13/aws-s3-misconfiguration-explained-fix/" },
        { type: "remediation", uri: "https://auth0.com/blog/fantastic-public-s3-buckets-and-how-to-find-them/" },
        { type: "remediation", uri: "https://aws.amazon.com/s3/features/block-public-access/" }
      ]
    }.merge(instance_details)

    to_return[:severity] = 2 if instance_details[:public]
  
  to_return
  end

end
end
end
