module Intrigue
  module Model
    module Mixins
    module CalculateProvider

      def provider
        providers = []
        aliases_and_name = [self].concat aliases

        aliases_and_name.each do |a|
          #puts "checking for #{a} in #{aliases_and_name}"

          if a.name =~ /\.omtrdc.net/
            providers << "Adobe Marketing Cloud"
          elsif a.name =~ /\.akam.net/ || a.name =~ /\.akamai.net/ || a.name =~ /\.akamaitechnologies.com/ || a.name =~ /\.edgesuite.net/ || a.name =~ /\.edgekey.net/
            providers << "Akamai"
          elsif a.name =~ /\.amazonaws.com/ || a.name =~ /\.cloudfront.net/
            providers << "Amazon AWS"
          elsif a.name =~ /^104.16/ || a.name =~ /104.20/
            providers << "Cloudflare"
          elsif a.name =~ /secureserver.net/
            providers << "Godaddy"
          elsif a.name =~ /\.ghs.google.com/ || a.name =~ /\.1e100.net/ || a.name =~ /\.googleusercontent.com/ || a.name =~ /\.googlehosted.com/
            providers << "Google"
          elsif a.name =~ /\.hosting.com/
            providers << "Hosting.com"
          elsif a.name =~ /\.hubspot.com/ || a.name =~ /\.hubspot.net/
            providers << "Hubspot"
          elsif a.name =~ /\.mktoweb.net/ || a.name =~ /\.mktoweb.com/
            providers << "Marketo"
          elsif a.name =~ /\.outlook.com/
            providers << "Microsoft"
          elsif a.name =~ /\.eloqua.com/
            providers << "Oracle (Eloqua)"
          elsif a.name =~ /\.unknown.prolexic.com/
            providers << "Prolexic"
          elsif a.name =~ /\.cloud-ips.com/
            providers << "Rackspace"
          elsif a.name =~ /\.exacttarget.com/
            providers << "Salesforce Marketing Cloud (ExactTarget)"
          elsif a.name =~ /\.algx.net/
            providers << "Verizon (XO)"
          elsif a.name =~ /\.webfaction/
            providers << "WebFaction"
          elsif a.name =~ /\.zendesk.com/
            providers << "Zendesk"
          end

        end

      providers.sort.uniq.join(" | ")
      end

    end
  end
end
end
