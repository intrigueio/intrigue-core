module Intrigue
  module Task
    class AwsRoute53 < BaseTask
      def self.metadata
        {
          name: 'aws_route53',
          pretty_name: 'AWS Route53 Gather Records',
          authors: ['Anas Ben Salah', 'maxim'],
          description: 'This task hits the Route53 API for enumerating DNS Records. Please ensure the <i>ListResourceRecordSets</i> permission is set in the policy for which the keys are associated with in order to retrieve records from a Hosted Zone. <br/><br/><b>Please note that if no Hosted Zone ID is provided; this task will retrieve records for all accessible Hosted Zones.</b>',
          references: ['https://docs.aws.amazon.com/Route53/latest/APIReference/Welcome.html'],
          type: 'discovery',
          passive: true,
          allowed_types: ['String'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => '__IGNORE__' } }],
          example_entity_placeholder: false,
          allowed_options: [
            { name: 'Hosted Zone ID', regex: 'alpha_numeric', default: '' }
          ],
          created_types: %w[DnsRecord Mailserver Nameserver]
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        aws_access_key = _get_task_config('aws_access_key_id')
        aws_secret_key = _get_task_config('aws_secret_access_key')
        hosted_zone_id = _get_option 'Hosted Zone ID'

        # route53 is global; region does not matter. set to us-east-1 to satisfy SDK.
        r53 = Aws::Route53::Client.new({ region: 'us-east-1', access_key_id: aws_access_key, secret_access_key: aws_secret_key })

        return nil unless access_key_valid? r53

        zone_ids = []
        record_sets = []

        if hosted_zone_id =~ /^Z[a-z0-9]*$/i
          zone_ids << hosted_zone_id
        else
          zone_ids = retrieve_all_hosted_zone_ids r53
        end

        unless zone_ids.nil?
          zone_ids.each do |zid|
            record_sets << r53.list_resource_record_sets({ 'hosted_zone_id': zid })
          rescue Aws::Route53::Errors::AccessDenied
            _log_error "API Key lacks permission to retrieve records from Zone: #{zid}."
          rescue Aws::Route53::Errors::NoSuchHostedZone
            _log_error "Invalid Host Zone ID: #{zid}."
          end
        end

        record_sets.each { |set| retrieve_record_names(set) } # maybe unless set.nil?
      end

      # TODO: check if key is valid
      def access_key_valid?(r53)
        # get an invalid hosted zone id to check if keys are valid
        r53.get_hosted_zone({ id: 'INVALIDZONE' })
      rescue Aws::Route53::Errors::InvalidClientTokenId
        _log_error 'Invalid Access Key ID.'
        false
      rescue Aws::Route53::Errors::SignatureDoesNotMatch
        _log_error 'Secret Access Key does not match Access Key ID.'
        false
      rescue Aws::Route53::Errors::NoSuchHostedZone
        # pass we expect this to happen if keys are correct
        true
      end

      # NO HOSTED ZONE PROVIDED - CALL THIS
      def retrieve_all_hosted_zone_ids(r53)
        begin
          response = r53.list_hosted_zones
        rescue Aws::Route53::Errors::AccessDenied
          _log_error 'API Key lacks permission to List Hosted Zones. Ensure the ListHostedZones permission is set or provide a Hosted Zone ID.'
          return nil
        end
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
              _log_good "Retrieved #{nameservers.size} NS records associated with #{item.name}"
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
