require 'concurrent'
require 'websocket_parser'

require_relative 'connection'

module Pakyow
  module Realtime
    class WebSocketReader
      include Concurrent::Async

      def initialize(parent)
        @key    = parent.key
        @parser = parent.parser
        @socket = parent.socket
        @parent = parent
      end

      def read
        loop do
          @parser << @socket.read_nonblock(16_384)
        end
      rescue ::IO::WaitReadable
        IO.select([@socket])
        retry
      rescue EOFError
        @parent.delegate.unregister(@key)
        @parent.shutdown
      end
    end

    # Hijacks a request, performs the handshake, and creates an async object
    # for handling incoming and outgoing messages in an asynchronous manner.
    #
    # @api private
    class Websocket < Connection
      attr_reader :parser, :socket, :key

      def initialize(req, key)
        @req = req
        @key = key

        @handshake = handshake!(req)
        @socket = hijack!(req)

        handle_handshake
      end

      def shutdown
        @socket.close if @socket && !@socket.closed?
        @reader = nil
      end

      def push(msg)
        json = JSON.pretty_generate(msg)
        logger.debug "(ws.#{@key}) sending message: #{json}\n"
        WebSocket::Message.new(json).write(@socket)
      end

      private

      def handshake!(req)
        WebSocket::ClientHandshake.new(:get, req.url, handshake_headers(req))
      end

      def hijack!(req)
        if req.env['rack.hijack']
          req.env['rack.hijack'].call
          return req.env['rack.hijack_io']
        else
          logger.info "there's no socket to hijack :("
        end
      end

      def handshake_headers(req)
        {
          'Upgrade' => req.env['HTTP_UPGRADE'],
          'Sec-WebSocket-Version' => req.env['HTTP_SEC_WEBSOCKET_VERSION'],
          'Sec-Websocket-Key' => req.env['HTTP_SEC_WEBSOCKET_KEY']
        }
      end

      def handle_handshake
        return if @socket.nil?

        if @handshake.valid?
          accept_handshake
          setup
        else
          fail_handshake
        end
      end

      def accept_handshake
        response = @handshake.accept_response
        response.render(@socket)
      end

      def fail_handshake
        error = @handshake.errors.first

        response = Rack::Response.new(400)
        response.render(@socket)

        fail HandshakeError, "(ws.#{@key}) error during handshake: #{error}"
      end

      def setup
        @parser = WebSocket::Parser.new

        @parser.on_message do |message|
          handle_ws_message(message)
        end

        @parser.on_error do |error|
          logger.error "(ws.#{@key}) encountered error #{error}"
          handle_ws_error(error)
        end

        @parser.on_close do |status, message|
          logger.info "(ws.#{@key}) client closed connection"
          handle_ws_close(status, message)
        end

        @parser.on_ping do |payload|
          handle_ws_ping(payload)
        end

        @reader = WebSocketReader.new(self)
        @reader.async.read
      end

      def handle_ws_message(message)
        parsed = JSON.parse(message)
        logger.debug "(ws.#{@key}) received message: #{JSON.pretty_generate(parsed)}\n"
        push(MessageHandler.handle(parsed, @req.env['rack.session']))
      rescue StandardError => e
        logger.error "(#{@key}): WebSocket encountered an error:"
        logger.error e.message

        e.backtrace.each do |line|
          logger.error line
        end
      end

      def handle_ws_error(_error)
        shutdown
      end

      def handle_ws_close(_status, _message)
        @socket << WebSocket::Message.close.to_data
        delegate.unregister(@key)

        shutdown
      end

      def handle_ws_ping(payload)
        @socket << WebSocket::Message.pong(payload).to_data
      end
    end
  end
end
