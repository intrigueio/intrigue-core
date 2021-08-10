module Intrigue
  module Issue
    class TelerikCVE201918935 < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-03-30',
          name: 'telerik_cve_2019_18935',
          pretty_name: 'Telerik Web UI Remote Code Execution (CVE-2019-18935)',
          severity: 1,
          category: 'vulnerability',
          status: 'confirmed',
          description: 'Progress Telerik UI for ASP.NET AJAX through 2019.3.1023 contains a .NET deserialization vulnerability in the RadAsyncUpload function. This is exploitable when the encryption keys are known due to the presence of CVE-2017-11317 or CVE-2017-11357, or other means. Exploitation can result in remote code execution. ',
          identifiers: [
            { type: 'CVE', name: 'CVE-2019-18935' }
          ],
          affected_software: [
            { vendor: 'Microsoft', product: 'ASP.NET' }
          ],
          references: [
            { type: 'description', uri: 'https://nvd.nist.gov/vuln/detail/CVE-2019-18935' },
            { type: 'description', uri: 'https://www.telerik.com/support/kb/aspnet-ajax/details/allows-javascriptserializer-deserialization' },
            { type: 'exploit', uri: 'https://github.com/noperator/CVE-2019-18935' }
          ],
          authors: ['Markus Wulftange', 'Paul Taylor', 'maxim']
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class TelerikCVE201918935 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end


      def telerik_file_upload_handler_registered?(uri)
        fp_string = 'RadAsyncUpload handler is registered succesfully, however, it may not be accessed directly'
        running = http_get_body("#{uri}/Telerik.Web.UI.WebResource.axd?type=rau").include? fp_string

        _log 'Telerik File Upload Handler does not exist on this endpoint; aborting.' unless running
        running
      end

      def extract_telerik_version(uri)
        parsed_uri = URI(uri)
        r = http_get_body("#{parsed_uri.scheme}://#{parsed_uri.host}") # get index page
        r.scan(/([\d|\.]+{5,9})/).flatten
      end

      def check
        vulnerable_versions = ['2019.3.1023', '2019.3.917', '2019.2.514', '2019.1.215', '2019.1.115', '2018.3.910',
                               '2018.2.710', '2018.2.516', '2018.1.117', '2015.2.623', '2014.1.403', '2017.3.913',
                               '2017.2.711', '2017.2.621', '2017.2.503', '2017.1.228', '2017.1.118', '2016.3.1027',
                               '2016.3.1018', '2016.3.914', '2016.2.607', '2016.2.504', '2016.1.225', '2016.1.113',
                               '2015.3.1111', '2015.3.930', '2015.2.826', '2015.2.729', '2015.2.604', '2015.1.225',
                               '2015.1.204', '2014.3.1024', '2014.2.724', '2014.2.618', '2014.1.225', '2013.3.1324',
                               '2013.3.1114', '2013.3.1015', '2013.2.717', '2013.2.611', '2013.1.417', '2013.1.403',
                               '2013.1.220', '2012.3.1308', '2012.3.1205', '2012.3.1016', '2012.2.912', '2012.2.724',
                               '2012.2.607', '2012.1.411', '2012.1.215', '2011.3.1305', '2011.31115', '2011.2915',
                               '2011.2712', '2011.1519', '2011.1413', '2011.1315', '2010.31317', '2010.31215',
                               '2010.31109', '2010.2929', '2010.2826', '2010.2713', '2010.1519', '2010.1415',
                               '2010.1309', '2009.31314', '2009.31208', '2009.31103', '2009.2826', '2009.2701',
                               '2009.1527', '2009.1402', '2009.1311', '2008.31314', '2008.31125', '2008.31105',
                               '2008.21001', '2008.2826', '2008.2723', '2008.1619', '2008.1515', '2008.1415',
                               '2007.31425', '2007.31314', '2007.31218', '2007.21107', '2007.21010', '2007.2918',
                               '2007.1626', '2007.1521', '2007.1423']

        uri = _get_entity_name
        return unless telerik_file_upload_handler_registered?(uri)

        is_vulnerable = (extract_telerik_version(uri) & vulnerable_versions).any?
        _log 'Target is not vulnerable.' unless is_vulnerable

        is_vulnerable
      end
    end
  end
end
