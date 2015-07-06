require 'resolv'

class DnsBruteSrvTask < BaseTask

  def metadata
    { :version => "1.0",
      :name => "dns_brute_srv",
      :pretty_name => "DNS Service Record Bruteforce",
      :authors => ["jcran"],
      :description => "Simple DNS Service Record Bruteforce",
      :references => [],
      :allowed_types => ["DnsRecord"],
      :example_entities => [{:type => "DnsRecord", :attributes => {:name => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "IPAddress", :default => "8.8.8.8" },
        {:name => "brute_list", :type => "String", :regex => "AlphaNumeric", :default =>
          [
            '_gc._tcp', '_kerberos._tcp', '_kerberos._udp', '_ldap._tcp',
            '_test._tcp', '_sips._tcp', '_sip._udp', '_sip._tcp', '_aix._tcp',
            '_aix._tcp', '_finger._tcp', '_ftp._tcp', '_http._tcp', '_nntp._tcp',
            '_telnet._tcp', '_whois._tcp', '_h323cs._tcp', '_h323cs._udp',
            '_h323be._tcp', '_h323be._udp', '_h323ls._tcp',
            '_h323ls._udp', '_sipinternal._tcp', '_sipinternaltls._tcp',
            '_sip._tls', '_sipfederationtls._tcp', '_jabber._tcp',
            '_xmpp-server._tcp', '_xmpp-client._tcp', '_imap.tcp',
            '_certificates._tcp', '_crls._tcp', '_pgpkeys._tcp',
            '_pgprevokations._tcp', '_cmp._tcp', '_svcp._tcp', '_crl._tcp',
            '_ocsp._tcp', '_PKIXREP._tcp', '_smtp._tcp', '_hkp._tcp',
            '_hkps._tcp', '_jabber._udp','_xmpp-server._udp', '_xmpp-client._udp',
            '_jabber-client._tcp', '_jabber-client._udp','_kerberos.tcp.dc._msdcs',
            '_ldap._tcp.ForestDNSZones', '_ldap._tcp.dc._msdcs', '_ldap._tcp.pdc._msdcs',
            '_ldap._tcp.gc._msdcs','_kerberos._tcp.dc._msdcs','_kpasswd._tcp','_kpasswd._udp'
          ]
        }
      ],
      :created_types => ["DnsRecord","IpAddress","Netsvc"]
    }
  end

  def run
    super

    # XXX = currently doesn't respect the 'resolver' option
    @resolver = Resolv::DNS.new # uses system default

    domain_name = _get_entity_attribute "name"
    resolver =  _get_option "resolver"

    brute_list = _get_option "brute_list"
    brute_list = brute_list.split(",") if brute_list.kind_of? String


    @task_log.good "Using srv list: #{brute_list}"

    brute_list.each do |srv_name|
      begin

        # Calculate the domain name
        brute_name = "#{srv_name}.#{domain_name}"

        # Try to resolve
        @resolver.getresources(brute_name, Resolv::DNS::Resource::IN::SRV).collect do |rec|

          # split up the record
          resolved_address = rec.target
          port = rec.port
          weight = rec.weight
          priority = rec.priority

          @task_log.good "Resolved Address #{resolved_address} for #{brute_name}" if resolved_address

          # If we resolved, create the right entities
          if resolved_address

            # Create a dns record
            domain = _create_entity("DnsRecord", {:name => brute_name })

            # Create a host to store the ip address
            host = _create_entity("IpAddress", {:name => resolved_address.to_s})

            # Create a service, and also associate that with our host.
            netsvc = _create_entity("NetSvc", {
              :name => "#{host[:attributes][:name]}:#{port}/tcp",
              :proto => "tcp",
              :port => port,
              :ip_address => "#{host[:attributes][:name]}"
            })

          end

        end
      rescue Exception => e
        @task_log.error "Hit exception: #{e}"
      end
    end
  end

end
