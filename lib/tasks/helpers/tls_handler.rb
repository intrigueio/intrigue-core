module Intrigue
  module Task
    module TlsHandler
    
      def get_certificate(hostname, port, timeout=30)
        # connect
        socket = connect_ssl_socket(hostname,port,timeout)
        return nil unless socket && socket.peer_cert
        # Grab the cert
        cert = OpenSSL::X509::Certificate.new(socket.peer_cert)
        # parse the cert
        socket.sysclose
        # get the names
        cert
      end
      
      def get_certificate_details(hostname, port)
        # connect
        socket = connect_ssl_socket(hostname,port,timeout=30)
            
        unless socket && socket.peer_cert 
          _log_error "Failed to extract certificate."
          return
        end

        # Parse the cert
        cert = OpenSSL::X509::Certificate.new(socket.peer_cert)

        # Create an SSL Certificate entity
        key_size = "#{cert.public_key.n.num_bytes * 8}" if cert.public_key && cert.public_key.respond_to?(:n)
        certificate_details = {
          "name" => "#{cert.subject.to_s.split("CN=").last} (#{cert.serial})",
          "version" => cert.version,
          "serial" => "#{cert.serial}",
          "not_before" => "#{cert.not_before}",
          "not_after" => "#{cert.not_after}",
          "subject" => "#{cert.subject}",
          "issuer" => "#{cert.issuer}",
          "key_length" => key_size,
          "signature_algorithm" => "#{cert.signature_algorithm}",
          "hidden_text" => "#{cert.to_text}"
        }

        # _log "Got certificat edetails #{certificate_details}"

        #return information
        certificate_details
      end
    
    end
    end
    end