module Intrigue
  module Task
  module Certificate
    
    def get_certificate_details(hostname, port)
      
      # connect
      # def initialize(host, port,  connect_timeout=10, timeout=10, ssl_context=nil)
      begin
        socket = connect_ssl_socket(hostname,port)
      rescue OpenSSL::SSL::SSLError => e 
        _log_error "Unable to connnect ssl certificate"
      end
          
      unless socket && socket.peer_cert 
        _log_error "Failed to extract certificate."
        return
      end
  
      # Parse the cert
      cert = OpenSSL::X509::Certificate.new(socket.peer_cert)
      cert_sha256_fingerprint = OpenSSL::Digest::SHA256.new(cert.to_der).to_s
  
      # Create an SSL Certificate entity
      key_size = "#{cert.public_key.n.num_bytes * 8}" if cert.public_key && cert.public_key.respond_to?(:n)
      certificate_details = {
        "name" => "#{cert.subject.to_s.split("CN=").last} (#{cert_sha256_fingerprint})",
        "version" => cert.version,
        "serial" => "#{cert.serial}",
        "not_before" => "#{cert.not_before}",
        "not_after" => "#{cert.not_after}",
        "subject" => "#{cert.subject}",
        "issuer" => "#{cert.issuer}",
        "key_length" => key_size,
        "signature_algorithm" => "#{cert.signature_algorithm}",
        "fingerprint_sha256" => "#{cert_sha256_fingerprint}",
        "hidden_text" => "#{cert.to_text}"
      }
  
      # _log "Got certificat edetails #{certificate_details}"
  
      #return information
      certificate_details
    end
  
  
    # See: https://raw.githubusercontent.com/zendesk/ruby-kafka/master/lib/kafka/ssl_socket_with_timeout.rb
    def connect_ssl_socket(hostname, port, timeout=10)
      
      s = Intrigue::SSLSocketWithTimeout.new(hostname, port,  timeout, timeout=10, ssl_context=nil)
  
      # fail if we can't connect
      ssl_socket = s.ssl_socket
      unless ssl_socket
        _log_error "Unable to connect!!"
        return nil
      end
  
    ssl_socket
    end
  
    def _select_with_timeout(socket, type, timeout)
      case type
      when :connect_read
        IO.select([socket], nil, nil, timeout)
      when :connect_write
        IO.select(nil, [socket], nil, timeout)
      when :read
        IO.select([socket], nil, nil, timeout)
      when :write
        IO.select(nil, [socket], nil, timeout)
      end
    end
  
    def parse_names_from_cert(cert, skip_suspicious=true)
  
      # default to empty alt_names
      alt_names = []
  
      # Check the subjectAltName property, and if we have names, here, parse them.
      cert.extensions.each do |ext|
        if "#{ext.oid}".match(/subjectAltName/)
  
          alt_names = ext.value.split(",").collect do |x|
            "#{x}".gsub(/DNS:/,"").gsub("IP Address:","").strip.gsub("*.","")
          end
          _log "Got cert's alt names: #{alt_names.inspect}"
  
          tlds = []
  
          # Iterate through, looking for trouble
          alt_names.each do |alt_name|
  
            # collect all top-level domains
            tlds << alt_name.split(".").last(2).join(".")
  
            universal_cert_domains = get_universal_cert_domains
  
            universal_cert_domains.each do |cert_domain|
              if alt_name.match(/#{cert_domain}$/) 
                _log "This is a universal #{cert_domain} certificate, returning empty list"
                return []
              end
            end
  
          end
  
          if skip_suspicious
            # Generically try to find certs that aren't useful to us
            suspicious_count = 20
            # Check to see if we have over suspicious_count top level domains in this cert
            if tlds.uniq.count >= suspicious_count
              # and then check to make sure none of the domains are greate than a quarter
              _log "This looks suspiciously like a third party cert... over #{suspicious_count} unique TLDs: #{tlds.uniq.count}"
              _log "Total Unique Domains: #{alt_names.uniq.count}"
              _log "Returning empty list"
              return []
            end
          end
        end
      end
  
    alt_names
    end
      
  end
  end
  end