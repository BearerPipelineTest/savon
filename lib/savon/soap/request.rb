require "httpi"
require "savon/soap/response"

module Savon
  module SOAP

    # = Savon::SOAP::Request
    #
    # Executes SOAP requests.
    class Request

      # Content-Types by SOAP version.
      ContentType = { 1 => "text/xml;charset=UTF-8", 2 => "application/soap+xml;charset=UTF-8" }

      # Expects an <tt>HTTPI::Request</tt> and a <tt>Savon::SOAP::XML</tt> object
      # to execute a SOAP request and returns the response.
      def self.execute(http, soap)
        new(http, soap).response
      end

      # Expects an <tt>HTTPI::Request</tt> and a <tt>Savon::SOAP::XML</tt> object.
      def initialize(http, soap)
        self.soap = soap
        self.http = configure(http)
      end

      attr_accessor :soap, :http

      # Executes the request and returns the response.
      def response
        @response ||= SOAP::Response.new(
          Savon.config.hooks.select(:soap_request).call(self) || with_logging { HTTPI.post(http) }
        )
      end

    private

      # Configures a given +http+ from the +soap+ object.
      def configure(http)
        http.url = soap.endpoint
        http.body = soap.to_xml
        http.headers["Content-Type"] = ContentType[soap.version]
        http.headers["Content-Length"] = soap.to_xml.bytesize.to_s
        http
      end

      # Logs the HTTP request, yields to a given +block+ and returns a <tt>Savon::SOAP::Response</tt>.
      def with_logging
        log_request http.url, http.headers, http.body
        response = yield
        log_response response.code, response.body
        response
      end

      # Logs the SOAP request +url+, +headers+ and +body+.
      def log_request(url, headers, body)
        Savon.config.logger.log "SOAP request: #{url}"
        Savon.config.logger.log headers.map { |key, value| "#{key}: #{value}" }.join(", ")
        Savon.config.logger.log_filtered body
      end

      # Logs the SOAP response +code+ and +body+.
      def log_response(code, body)
        Savon.config.logger.log "SOAP response (status #{code}):"
        Savon.config.logger.log body
      end

    end
  end
end