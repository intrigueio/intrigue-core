module Intrigue
module Model
module Mixins
module MatchExceptions

  # Method gives us a true/false, depending on whether the entity is in an
  # exception list. Currently only used on project, but could be included
  # in task_result or scan_result. Note that they'd need the "additional_exception_list"
  # and "use_standard_exceptions" fields on the object
  def exception_entity?(entity_name, type_string=nil, skip_regexes)

    # SEED ENTITY, CANT BE AN EXCEPTION
    if seed_entity?(type_string,entity_name)
      return false
    end

    # Check standard exceptions first
    # (which now reside in Intrigue::TraverseExceptions)
    if non_traversable?(entity_name,type_string, skip_regexes)
      return true
    end

    # if we don't have a list, safe to return false now, otherwise proceed to additional exceptions
    # which are provided as an attribute on the object
    return false unless additional_exception_list && !additional_exception_list.empty?

    # check additional exception strings
    is_an_exception = false
    additional_exception_list.each do |x|
      # this needs two cases:
      # 1) case where we're an EXACT match (ey.com)
      # 2) case where we're a subdomain of an exception domain (x.ey.com)
      # neither of these cases should match the case: jcpenney.com
      if entity_name.downcase =~ /^#{Regexp.escape(x.downcase)}(:[0-9]*)?$/ ||
        entity_name.downcase =~ /^.*\.#{Regexp.escape(x.downcase)}(:[0-9]*)?$/
        return true
      end
    end

  false
  end

  def standard_name_exceptions
    [
      /^.*\.[a-z]-msedge.net(:[0-9]*)?$/,
      /^.*\.1e100.net(:[0-9]*)?$/,
      /^.*\.2o7.net(:[0-9]*)?$/,
      /^.*\.adobecqms.net(:[0-9]*)?$/,
      /^.*\.akadns.net(:[0-9]*)?$/,
      /^.*\.akam.net(:[0-9]*)?$/,
      /^.*\.akamai.net(:[0-9]*)?$/,
      /^.*\.akamai.com(:[0-9]*)?$/,
      /^.*\.akamaiedge.net(:[0-9]*)?$/,
      /^.*\.akamaiedge-staging.net(:[0-9]*)?$/,
      /^.*\.akamaihd-staging.net(:[0-9]*)?$/,
      /^.*\.akamaihd.net(:[0-9]*)?$/,
      /^.*\.akamaistream.net(:[0-9]*)?$/,
      /^.*\.akamaitechnologies.net(:[0-9]*)?$/,
      /^.*\.akamaitechnologies.com(:[0-9]*)?$/,
      /^.*\.akamaized-staging.net(:[0-9]*)?$/,
      /^.*\.akamaized.net(:[0-9]*)?$/,
      /^.*\.amazonaws.com(:[0-9]*)?$/,
      /^.*\.android.clients.google.com(:[0-9]*)?$/,
      /^.*\.android.com(:[0-9]*)?$/,
      /^.*\.anubisnetworks.com(:[0-9]*)?$/,
      /^.*\.apache.org(:[0-9]*)?$/,
      /^.*\.\.arpa(:[0-9]*)?$/,
      /^.*\.atlinkservices.com(:[0-9]*)?$/,
      /^.*\.azure-mobile.net(:[0-9]*)?$/,
      /^.*\.azureedge-test.net(:[0-9]*)?$/,
      /^.*\.azureedge.net(:[0-9]*)?$/,
      /^.*\.azurewebsites.net(:[0-9]*)?$/,
      /^.*\.bfi0.com(:[0-9]*)?$/,
      /^.*\.bigcommerce.com(:[0-9]*)?$/,
      /^.*\.bluehost.com(:[0-9]*)?$/,
      /^.*\.brightcove.com(:[0-9]*)?$/,
      /^.*\.bronto.com(:[0-9]*)?$/,
      /^.*\.bydiscourse.com(:[0-9]*)?$/,
      /^.*\.chtah.com(:[0-9]*)?$/,
      /^.*\.cheetahmail.com(:[0-9]*)?$/,
      /^.*\.clickdimensions.com(:[0-9]*)?$/,
      /^.*\.cloudapp.net(:[0-9]*)?$/,
      /^.*\.cloudflare.com(:[0-9]*)?$/,
      /^.*\.cloudfront.net(:[0-9]*)?$/,
      /^.*\.cloudflare-dns.com(:[0-9]*)?$/,
      /^.*\.convertlanguage.com(:[0-9]*)?$/,
      /^.*\.corporate-ir.net(:[0-9]*)?$/,
      /^.*\.decipherinc.com(:[0-9]*)?$/,
      /^.*\.discourse.org(:[0-9]*)?$/,
      /^.*\.drupal.org(:[0-9]*)?$/,
      /^.*\.ed[0-9]+.com(:[0-9]*)?$/,
      /^.*\.edgecastcdn.net(:[0-9]*)?$/,
      /^.*\.edgekey.net(:[0-9]*)?$/,
      /^.*\.edgekey-staging.net(:[0-9]*)?$/,
      /^.*\.edgesuite.net(:[0-9]*)?$/,
      /^.*\.egnyte.com(:[0-9]*)?$/,
      /^.*\.eloqua.com(:[0-9]*)?$/,
      /^.*\.exacttarget.com(:[0-9]*)?$/,
      /^.*\.facebook.com(:[0-9]*)?$/,
      /^.*\.fastly.net(:[0-9]*)?$/,
      /^.*\.feeds2.feedburner.com(:[0-9]*)?$/,
      /^.*\.footprintdns.com(:[0-9]*)?$/,
      /^.*\.force.com(:[0-9]*)?$/,
      /^.*\.g.co(:[0-9]*)?$/,
      /^.*\.gandi.net(:[0-9]*)?$/,
      /^.*\.gcs-web.com(:[0-9]*)?$/,
      /^.*\.ghs.google.com(:[0-9]*)?$/,
      /^.*\.github.com(:[0-9]*)?$/,
      /^.*\.github.io(:[0-9]*)?$/,
      /^.*\.goo.gl(:[0-9]*)?$/,
      /^.*\.google-analytics.com(:[0-9]*)?$/,
      /^.*\.githubapp.com(:[0-9]*)?$/,
      /^.*\.google.ca(:[0-9]*)?$/,
      /^.*\.google.cl(:[0-9]*)?$/,
      /^.*\.google.co.in(:[0-9]*)?$/,
      /^.*\.google.co.jp(:[0-9]*)?$/,
      /^.*\.google.co.uk(:[0-9]*)?$/,
      /^.*\.google.com(:[0-9]*)?$/,
      /^.*\.google.com.ar(:[0-9]*)?$/,
      /^.*\.google.com.au(:[0-9]*)?$/,
      /^.*\.google.com.br(:[0-9]*)?$/,
      /^.*\.google.com.co(:[0-9]*)?$/,
      /^.*\.google.com.mx(:[0-9]*)?$/,
      /^.*\.google.com.tr(:[0-9]*)?$/,
      /^.*\.google.com.vn(:[0-9]*)?$/,
      /^.*\.google.de(:[0-9]*)?$/,
      /^.*\.google.es(:[0-9]*)?$/,
      /^.*\.google.fr(:[0-9]*)?$/,
      /^.*\.google.hu(:[0-9]*)?$/,
      /^.*\.google.it(:[0-9]*)?$/,
      /^.*\.google.nl(:[0-9]*)?$/,
      /^.*\.google.pl(:[0-9]*)?$/,
      /^.*\.google.pt(:[0-9]*)?$/,
      /^.*\.googleadapis.com(:[0-9]*)?$/,
      /^.*\.googleapis.cn(:[0-9]*)?$/,
      /^.*\.googlecommerce.com(:[0-9]*)?$/,
      /^.*\.googlehosted.com(:[0-9]*)?$/,
      /^.*\.googlemail.com(:[0-9]*)?$/,
      /^.*\.googlevideo.com(:[0-9]*)?$/,
      /^.*\.gigya.com(:[0-9]*)?$/,
      /^.*\.gridserver.com(:[0-9]*)?$/,
      /^.*\.gstatic.cn(:[0-9]*)?$/,
      /^.*\.gstatic.com(:[0-9]*)?$/,
      /^.*\.gvt1.com(:[0-9]*)?$/,
      /^.*\.gvt2.com(:[0-9]*)?$/,
      /^.*\.herokuapp.com(:[0-9]*)?$/,
      /^.*\.herokudns.com(:[0-9]*)?$/,
      /^.*\.herokussl.com(:[0-9]*)?$/,
      /^.*\.hostgator.com(:[0-9]*)?$/,
      /^.*\.hscoscdn[0-9]+.net(:[0-9]*)?$/,
      /^.*\.hubspot.com(:[0-9]*)?$/,
      /^.*\.hubspot.net(:[0-9]*)?$/,
      /^.*\.in-addr.arpa(:[0-9]*)?$/,
      /^.*\.incapdns.net(:[0-9]*)?$/,
      /^.*\.incapsula.com(:[0-9]*)?$/,
      /^.*\.ink1001.com(:[0-9]*)?$/, # Movable Ink
      /^.*\.instagram.com(:[0-9]*)?$/,
      /^.*\.int-i.net(:[0-9]*)?$/, # https://intinc.com/company/
      /^.*\.invision.net(:[0-9]*)?$/,
      /^.*\.jobing.com(:[0-9]*)?$/,
      /^.*\.localhost(:[0-9]*)?$/,
      /^.*\.lookbookhq.com(:[0-9]*)?$/,
      /^.*\.linkedin.com(:[0-9]*)?$/,
      /^.*\.live.net(:[0-9]*)?$/,
      /^.*\.live.com(:[0-9]*)?$/,
      /^.*\.lync.com(:[0-9]*)?$/,
      /^.*\.mailgun.info(:[0-9]*)?$/,
      /^.*\.mailgun.org(:[0-9]*)?$/,
      /^.*\.mailketeer.com(:[0-9]*)?$/,
      /^.*\.mandrillapp.com(:[0-9]*)?$/,
      /^.*\.marketo.com(:[0-9]*)?$/,
      /^.*\.metric.gstatic.com(:[0-9]*)?$/,
      /^.*\.mktossl.com(:[0-9]*)?$/,
      /^.*\.mktoweb.com(:[0-9]*)?$/,
      /^.*\.mkto-[a-z]+[0-9]+.com(:[0-9]*)?$/,# marketo branding domain
      /^.*\.microsoft.com(:[0-9]*)?$/,
      /^.*\.microsoftonline.com(:[0-9]*)?$/,
      /^.*\.mpmsx.net(:[0-9]*)?$/,
      /^.*\.mtsvc.net(:[0-9]*)?$/,
      /^.*\.msn.com(:[0-9]*)?$/,
      /^.*\.oclc.org(:[0-9]*)?$/,
      /^.*\.office.com(:[0-9]*)?$/,
      /^.*\.office.net(:[0-9]*)?$/,
      /^.*\.office365.com(:[0-9]*)?$/,
      /^.*\.outlook.com(:[0-9]*)?$/,
      /^.*\.ogp.me(:[0-9]*)?$/,
      /^.*\.outlook.com(:[0-9]*)?$/,
      /^.*\.pardot.com(:[0-9]*)?$/,
      /^.*\.parklogic.com(:[0-9]*)?$/,
      /^.*\.photorank.me(:[0-9]*)?$/,
      /^.*\.plus.google.com(:[0-9]*)?$/,
      /^.*\.posterous.com(:[0-9]*)?$/,
      /^.*\.purl.org(:[0-9]*)?$/,
      /^.*\.q4web.com(:[0-9]*)?$/,
      /^.*\.rdfs.org(:[0-9]*)?$/,
      /^.*\.root-servers.net(:[0-9]*)?$/,
      /^.*\.schema.org(:[0-9]*)?$/,
      /^.*\.salesforce.com(:[0-9]*)?$/,
      /^.*\.sendgrid.net(:[0-9]*)?$/,
      /^.*\.secureserver.net(:[0-9]*)?$/,
      /^.*\.sharepoint.com(:[0-9]*)?$/,
      /^.*\.sharepointonline.com(:[0-9]*)?$/,
      /^.*\.siftscience.com(:[0-9]*)?$/,
      /^.*\.silverpop.com(:[0-9]*)?$/,
      /^.*\.squarespace.com(:[0-9]*)?$/,
      /^.*\.statuspage.io(:[0-9]*)?$/,
      /^.*\.statusio.com(:[0-9]*)?$/,
      /^.*\.sumocdn.net(:[0-9]*)?$/,
      /^.*\.twitter.com(:[0-9]*)?$/,
      /^.*\.uberflip.com(:[0-9]*)?$/,
      /^.*\.ultradns.com(:[0-9]*)?$/,
      /^.*\.unifiedlayer.com(:[0-9]*)?$/,
      /^.*\.urchin.com(:[0-9]*)?$/,
      /^.*\.url.google.com(:[0-9]*)?$/,
      /^.*\.v0cdn.net(:[0-9]*)?$/,
      /^.*\.volusion.com(:[0-9]*)?$/,
      /^.*\.w3.org(:[0-9]*)?$/,
      /^.*\.websitewelcome.com(:[0-9]*)?$/,
      /^.*\.weebly.com(:[0-9]*)?$/,
      /^.*\.windows.net(:[0-9]*)?$/,
      /^.*\.windowsphone-int.net(:[0-9]*)?$/,
      /^.*\.windowsphone.com(:[0-9]*)?$/,
      /^.*\.wordpress.com(:[0-9]*)?$/,
      /^.*\.wpengine.com(:[0-9]*)?$/,
      /^.*\.www.goo.gl(:[0-9]*)?$/,
      /^.*\.xmlns.com(:[0-9]*)?$/,
      /^.*\.youtu.be(:[0-9]*)?$/,
      /^.*\.youtube-nocookie.com(:[0-9]*)?$/,
      /^.*\.youtube.com(:[0-9]*)?$/,
      /^.*\.youtubeeducation.com(:[0-9]*)?$/,
      /^.*\.ytimg.com(:[0-9]*)?$/,
      /^.*\.zendesk.com(:[0-9]*)?$/,
      /^.*\.zepheira.com(:[0-9]*)?$/,
      /^.*\.1e100.com(:[0-9]*)?$/
    ]
  end

  def standard_ip_exceptions

    # incapsula: /107\.154\.*/

    # RFC1918
    #/^172\.16\..*$/||
    #/^192\.168\..*$/||
    #/^10\..*$/

    ip_exceptions = [
      /^23\..*$/,
      /^2600:1400.*$/,
      /^2600:1409.*$/,
      /^127\..*$/,
      /^0.0.0.0$/
    ]
  end

  # this method matches entities to a static list of known-non-traversable
  # entities. it'll return the regex that matches if it matches, otherwise,
  # it'll return false for a non-match
  #
  # if a skip_exception is provided, it'll be removed from the list. this is
  # key for situations when you've got a manually created domain that would
  # otherwise be an exception
  #
  # RETURNS A REGEX OR FALSE
  #
  def non_traversable?(entity_name, type_string="Domain", skip_exceptions=[])

    if type_string == "IpAddress"

      (standard_ip_exceptions - skip_exceptions).each do |exception|
        return exception if (entity_name =~ exception)
      end

    elsif (type_string == "Domain" || type_string == "DnsRecord" || type_string == "Uri" )

      (standard_name_exceptions - skip_exceptions).each do |exception|
        return exception if (entity_name =~ exception ||  ".#{entity_name}" =~ exception)
      end

    end

  false
  end

end
end
end
end
