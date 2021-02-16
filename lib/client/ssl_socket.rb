# frozen_string_literal: true
require "socket"

# modified from an original zendesk ruby-kafka version

module Intrigue

  # Opens sockets in a non-blocking fashion, ensuring that we're not stalling
  # for long periods of time.
  #
  # It's possible to set timeouts for connecting to the server, for reading data,
  # and for writing data. Whenever a timeout is exceeded, Errno::ETIMEDOUT is
  # raised.
  #
  class SSLSocketWithTimeout

    attr_accessor :ssl_socket

    # Opens a socket.
    #
    # @param host [String]
    # @param port [Integer]
    # @param connect_timeout [Integer] the connection timeout, in seconds.
    # @param timeout [Integer] the read and write timeout, in seconds.
    # @param ssl_context [OpenSSL::SSL::SSLContext] which SSLContext the ssl connection should use
    # @raise [Errno::ETIMEDOUT] if the timeout is exceeded.
    def initialize(host, port,  connect_timeout=10, timeout=10, ssl_context=nil)
      addr = Socket.getaddrinfo(host, nil)
      sockaddr = Socket.pack_sockaddr_in(port, addr[0][3])

      @connect_timeout = connect_timeout || 10
      @timeout = timeout || 10

      unless ssl_context 
        # create ssl_context 
        ssl_context = OpenSSL::SSL::SSLContext.new
        #self.options |= OpenSSL::SSL::OP_ALL
        #ssl_context.ssl_version = OpenSSL::SSL::TLS1_2_VERSION
        #ssl_context.ciphers = "ALL"
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        ssl_context.verify_hostname = false
      end
      

      @tcp_socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)
      @tcp_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

      # first initiate the TCP socket
      begin
        # Initiate the socket connection in the background. If it doesn't fail
        # immediately it will raise an IO::WaitWritable (Errno::EINPROGRESS)
        # indicating the connection is in progress.
        @tcp_socket.connect_nonblock(sockaddr)
      rescue IO::WaitWritable
        # select will block until the socket is writable or the timeout
        # is exceeded, whichever comes first.
        unless select_with_timeout(@tcp_socket, :connect_write)
          # select returns nil when the socket is not ready before timeout
          # seconds have elapsed
          @tcp_socket.close
          raise Errno::ETIMEDOUT
        end

        begin
          # Verify there is now a good connection.
          @tcp_socket.connect_nonblock(sockaddr)
        rescue Errno::EISCONN
          # The socket is connected, we're good!
        end
      end

      # once that's connected, we can start initiating the ssl socket
      @ssl_socket = OpenSSL::SSL::SSLSocket.new(@tcp_socket, ssl_context)
      
      # set the hostname to account for SNI 
      @ssl_socket.hostname = host

      begin
        # Initiate the socket connection in the background. If it doesn't fail
        # immediately it will raise an IO::WaitWritable (Errno::EINPROGRESS)
        # indicating the connection is in progress.
        # Unlike waiting for a tcp socket to connect, you can't time out ssl socket
        # connections during the connect phase properly, because IO.select only partially works.
        # Instead, you have to retry.
        @ssl_socket.connect_nonblock
      rescue Errno::EAGAIN, Errno::EWOULDBLOCK, IO::WaitReadable
        if select_with_timeout(@ssl_socket, :connect_read)
          retry
        else
          @ssl_socket.close
          close
          raise Errno::ETIMEDOUT
        end
      rescue IO::WaitWritable
        if select_with_timeout(@ssl_socket, :connect_write)
          retry
        else
          close
          raise Errno::ETIMEDOUT
        end
      end
    end

    # Reads bytes from the socket, possible with a timeout.
    #
    # @param num_bytes [Integer] the number of bytes to read.
    # @raise [Errno::ETIMEDOUT] if the timeout is exceeded.
    # @return [String] the data that was read from the socket.
    def read(num_bytes)
      buffer = String.new

      until buffer.length >= num_bytes
        begin
          # Unlike plain TCP sockets, SSL sockets don't support IO.select
          # properly.
          # Instead, timeouts happen on a per read basis, and we have to
          # catch exceptions from read_nonblock and gradually build up
          # our read buffer.
          buffer << @ssl_socket.read_nonblock(num_bytes - buffer.length)
        rescue IO::WaitReadable
          if select_with_timeout(@ssl_socket, :read)
            retry
          else
            raise Errno::ETIMEDOUT
          end
        rescue IO::WaitWritable
          if select_with_timeout(@ssl_socket, :write)
            retry
          else
            raise Errno::ETIMEDOUT
          end
        end
      end

      buffer
    end

    # Writes bytes to the socket, possible with a timeout.
    #
    # @param bytes [String] the data that should be written to the socket.
    # @raise [Errno::ETIMEDOUT] if the timeout is exceeded.
    # @return [Integer] the number of bytes written.
    def write(bytes)
      loop do
        written = 0
        begin
          # unlike plain tcp sockets, ssl sockets don't support IO.select
          # properly.
          # Instead, timeouts happen on a per write basis, and we have to
          # catch exceptions from write_nonblock, and gradually build up
          # our write buffer.
          written += @ssl_socket.write_nonblock(bytes)
        rescue Errno::EFAULT => error
          raise error
        rescue OpenSSL::SSL::SSLError, Errno::EAGAIN, Errno::EWOULDBLOCK, IO::WaitWritable => error
          if error.is_a?(OpenSSL::SSL::SSLError) && error.message == 'write would block'
            if select_with_timeout(@ssl_socket, :write)
              retry
            else
              raise Errno::ETIMEDOUT
            end
          else
            raise error
          end
        end

        # Fast, common case.
        break if written == bytes.size

        # This takes advantage of the fact that most ruby implementations
        # have Copy-On-Write strings. Thusly why requesting a subrange
        # of data, we actually don't copy data because the new string
        # simply references a subrange of the original.
        bytes = bytes[written, bytes.size]
      end
    end

    def close
      @tcp_socket.close
      @ssl_socket.close
    end

    def closed?
      @tcp_socket.closed? || @ssl_socket.closed?
    end

    def set_encoding(encoding)
      @tcp_socket.set_encoding(encoding)
    end

    def select_with_timeout(socket, type)
      case type
      when :connect_read
        IO.select([socket], nil, nil, @connect_timeout)
      when :connect_write
        IO.select(nil, [socket], nil, @connect_timeout)
      when :read
        IO.select([socket], nil, nil, @timeout)
      when :write
        IO.select(nil, [socket], nil, @timeout)
      end
    end
  end
  
end
