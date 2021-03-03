
module Intrigue
module Issue
class AwsS3BucketHttpSplitting < BaseIssue

  def self.generate(instance_details={})
    
    to_return = {
      added: "2021-03-02",
      name: "aws_s3_bucket_http_splitting",
      pretty_name: "AWS S3 Bucket HTTP Splitting",
      severity: 2,
      status: "confirmed",
      category: "misconfiguration",
      description: "HTTP Splitting exploit in AWS S3 bucket was discovered.",
      remediation: "Try to use safe variables, forbid the use of the new line symbol in the exclusive range and it could be a good idea to validate $uri",
      affected_software: [ 
          { :vendor => "Nginx", :product => "Nginx" },
        ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intels
        { type: "description", uri: "https://labs.detectify.com/2021/02/18/middleware-middleware-everywhere-and-lots-of-misconfigurations-to-fix/" },
        { type: "remediation", uri: "https://github.com/yandex/gixy/blob/master/docs/en/plugins/httpsplitting.md" }
      ],
      task: "vuln/aws_s3_bucket_http_splitting"
    }.merge(instance_details)
  
    to_return[:severity] = 1 if instance_details[:public]
  
  to_return
  end

end
end
end
