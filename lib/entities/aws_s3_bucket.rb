module Intrigue
module Entity
class AwsS3Bucket < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "AwsS3Bucket",
      :description => "An S3 Bucket",
      :user_creatable => false
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


module Intrigue
module Task
class EnrichAwsS3Bucket < BaseTask

  def self.metadata
    {
      :name => "enrich/aws_s3_bucket",
      :pretty_name => "Enrich AWS S3 Bucket",
      :authors => ["jcran"],
      :description => "This task takes an S3 bucket and gathers all objects within it.",
      :references => [],
      :type => "enrichment",
      :passive => true,
      :allowed_types => ["AwsS3Bucket"],
      :example_entities => [
        {"type" => "AwsS3Bucket", "details" => {"name" => "https://s3.amazonaws.com/bucket"}}
      ],
      :allowed_options => [
        {:name => "notify_slack",  :regex => "boolean", :default => true },
        {:name => "large_file_size", :regex => "integer", :default => 15},
      ],
      :created_types => ["DnsRecord"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    bucket_uri = _get_entity_detail("uri") || _get_entity_name
    bucket_uri.chomp!("/")

    unless bucket_uri =~ /s3.amazonaws.com/
      _log_error "Not an Amazon S3 link?"
      return
    end

    # DO THE BRUTEFORCE
    # TODO - this is very naive right now, and will miss
    # large swaths of files that have similar names. make a point
    # of making this much smarter without doing too much bruting...

    all_files = []
    downloadable_files = []
    interesting_files = []

    # for each letter of the alphabet...
    [*('a'..'z'),*('A'..'Z'),*('0'..'9')].each do |letter|
      result = get_contents_unauthenticated(bucket_uri,letter)

      if !result
        _log_error "Got empty response for #{letter} on #{bucket_uri}"
        next
      end

      # otherwise, save the results
      all_files.concat(result[:all_files])
      interesting_files.concat(result[:interesting_files])
      downloadable_files.concat(result[:downloadable_files])

    end

    _set_entity_detail("all_files", all_files)
    _set_entity_detail("downloadable_files", downloadable_files)
    _set_entity_detail("interesting_files", interesting_files)

    _log "interesting files: #{interesting_files}"
    _log "downloadable files: #{downloadable_files}"

    # this should be a "Finding" or some sort of success event ?
    if interesting_files.sort.uniq.count > 0
      _log_good "Notifying slack on... #{interesting_files}"
      _call_handler("slackbot_buckets") if _get_option("notify_slack")
    end

    _finalize_enrichment
  end

  def get_contents_unauthenticated(s3_uri, prefix)
    full_uri = "#{s3_uri}?prefix=#{prefix}&max-keys=1000"

    resp = http_get_body("#{full_uri}")
    return false unless resp

    all_files = []
    downloadable_files = []
    interesting_files = []

    doc = Nokogiri::HTML(resp)
    if  ( doc.xpath("//code").text =~ /NoSuchBucket/ ||
          doc.xpath("//code").text =~ /InvalidBucketName/ ||
          doc.xpath("//code").text =~ /AllAccessDisabled/ ||
          doc.xpath("//code").text =~ /AccessDenied/
          doc.xpath("//code").text =~ /PermanentRedirect/ )
      _log_error "Got response: #{doc.xpath("//code").text} (#{s3_uri})"

    else # check each file size
      doc.xpath("//contents").each do |item|

        # look at each item
        key = item.xpath("key").text
        size = item.xpath("size").text.to_i
        item_uri = "#{s3_uri}/#{key}"

        # request it
        bucket_resp = http_request(:head, item_uri)

        # handle failure
        if !bucket_resp
          # add to our array
          all_files << { :uri => "#{item_uri}", :code => "FAIL" }
          next
        end

        if bucket_resp.code.to_i == 200
          downloadable_files << { :uri => "#{item_uri}", :code => "#{bucket_resp.code}" }
        end

        # handle our interesting files
        large_file_size = _get_option("large_file_size")
        file_size = (size * 1.0) / 1000000
        if ((file_size > large_file_size) && bucket_resp.code.to_i == 200)
          unless matches_ignore_list(item_uri)
            _log "Interesting File: #{item_uri} (#{size*1.0/1000000}MB)"
            interesting_files << "#{item_uri}"
          end
        end
      end # end parsing of the bucket
    end # end if

    #return hash
    {
      all_files: all_files, # { :uri => "#{item_uri}", :code => "#{resp.code}" }
      downloadable_files: downloadable_files, # http://blahblah.s3.amazonaws.com
      interesting_files: interesting_files  # http://blahblah.s3.amazonaws.com
    }
  end

  def matches_ignore_list(uri)
    [
      /^.*\.avi$/i,
      /^.*\.bmp$/i,
      /^.*\.flv$/i,
      /^.*\.jpg$/i,
      /^.*\.m4a$/i,
      /^.*\.m4v$/i,
      /^.*\.mov$/i,
      /^.*\.mp3$/i,
      /^.*\.mp4$/i,
      /^.*\.ogg$/i,
      /^.*\.ogv$/i,
      /^.*\.png$/i,
      /^.*\.tif$/i,
      /^.*\.wmv$/i
    ].each do |regex|
      return true if uri =~ regex
    end

  false
  end

end
end
end
