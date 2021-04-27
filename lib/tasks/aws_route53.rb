module Intrigue
module Task
class AwsRoute53 < BaseTask

  def self.metadata
    {
      :name => 'aws_route53',
      :pretty_name => 'AWS Route53 Zone Pull',
      :authors => ['Anas Ben Salah', 'maxim'],
      :description => 'This task hits the Route53 API for enumerating Dns Records for a specific domain. Please ensure the following policy perimssions are set:<br /> - maxim<br /> - maxim<br> Please note that if no Hosted Zone ID is provided; this task will retrieve records for all accessible Hosted Zones.',
      :references => ['https://docs.aws.amazon.com/Route53/latest/APIReference/Welcome.html'],
      :type => 'discovery',
      :passive => true,
      :allowed_types => ['String'],
      :example_entities => [{ 'type' => 'String', 'details' => { 'name' => 'Hosted Zone ID (Optional)' } }],
      :allowed_options => [
       # { :name => 'Hosted Zone ID (Optional)', :regex => "alpha_numeric", :default => '' }
      ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    r53 = Aws::Route53::Client.new(
      {
        region: _get_task_config('aws_region'),
        access_key_id: _get_task_config('aws_access_key_id'),
        secret_access_key: _get_task_config('aws_secret_access_key')
      }
    )
    begin
      # get an invalid hosted zone id to check if keys are valid
      r53.get_hosted_zone({ id: 'INVALIDZONE' })
    rescue Aws::Route53::Errors::InvalidClientTokenId
      _log_error 'Invalid Access Key ID.'
      return nil
    rescue Aws::Route53::Errors::SignatureDoesNotMatch
      _log_error 'Secret Access Key does not match Access Key ID.'
      return nil
    rescue Aws::Route53::Errors::NoSuchHostedZone
      # pass we expect this to happen if keys are correct
    end

    zone_ids = []
    record_sets = []

    if _get_entity_name =~ /^Z[a-z0-9]*$/i # hosted zone always begins with a Z (there is no set amount of chars)
      zone_ids << _get_entity_name
    else
      zone_ids = retrieve_all_hosted_zone_ids r53
    end

    zone_ids.each do |zid|
      record_sets << r53.list_resource_record_sets({ :hosted_zone_id => zid })
    rescue Aws::Route53::Errors::AccessDenied
      _log_error "API Key lacks permission to retrieve records from Zone: #{zid}."
    rescue Aws::Route53::Errors::NoSuchHostedZone
      _log_error "Invalid Host Zone ID: #{zid}."
    end

    record_sets.each { |set| retrieve_record_names(set) } # maybe unless set.nil?
  end # end run

  # NO HOSTED ZONE PROVIDED - CALL THIS
  def retrieve_all_hosted_zone_ids(r53)
    begin
      response = r53.list_hosted_zones
    rescue Aws::Route53::Errors::AccessDenied
      _log_error 'API Key lacks permission to List Hosted Zones. Ensure the ListHostedZones permission is set or provide a Hosted Zone ID.'
      return nil
    end
    # what if there are no hosted zones? need to create new aws account to test this out
    response.hosted_zones.map { |hz| hz.id.split('/')[2] if hz }
  end

  def retrieve_record_names(records)
    subdomain_regex = /([a-zA-Z0-9][a-zA-Z0-9.-]+[a-zA-Z0-9])/
    records.each do |record|
      record.resource_record_sets.each do |item|
        case item.type
        when 'NS'
          # only save the values
          nameservers = item.resource_records.map(&:value)
          _log_good "Retrieved #{nameservers.size} NS records."
          nameservers.compact.uniq.each { |n| _create_entity 'Nameserver', 'name' => n.scan(subdomain_regex).last.first }
        when 'MX'
          # only save the values -> may save the record name as well however most of the time its set for the domain rather than a specific subdomain
          mxvalues = item.resource_records.map(&:value)
          mxvalues.compact.uniq.each { |m| _create_entity 'Mailserver', 'name' => m.scan(subdomain_regex).last.first }
        when 'A', 'CNAME', 'AAAA', 'SRV'
          _log_good "Retrieved the following #{item.type} Record: #{item.name.scan(subdomain_regex).last.first}"
          _create_entity 'DnsRecord', 'name' => item.name.scan(subdomain_regex).last.first
        end
      end
    end
  end

end
end
end
