
require 'logger'
$logger = Logger.new(STDOUT)
$logger.level = Logger::WARN


module RGeoServer
  module RestApiClient

    include RGeoServer::GeoServerUrlHelpers
    include ActiveSupport::Benchmarkable

    # Instantiates a rest client with passed configuration
    # @param [Hash] c configuration
    # return <RestClient::Resource>
    def rest_client c
      #RestClient::Resource.new(c[:url], :user => c[:user], :password => c[:password], :headers => c[:headers])
      RestClient::Resource.new(c[:url], c)
    end

    def client config = {}
      @client ||= rest_client(self.config.merge(config))
    end

    def gwc_client config = {}
      c = self.config.merge(config)
      c[:url] = c[:geowebcache_url]
      @gwc_client ||= rest_client(c)
    end


    def headers format
      sym = :xml || format.to_sym
      {:accept => sym, :content_type=> sym}
    end

    # Search a resource in the catalog
    # @param [OrderedHash] what
    # @param [Hash] options
    def search what, options = {}
      h = options.delete(:headers) || headers(:xml)
      resources = client[url_for(what, options)]
      resources.options[:headers] = h
      begin
        return resources.get
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "Error listing #{what.inspect}. See $logger for details"
      end
    end

    # Do an action on an arbitrary URL path within the catalog
    # Default method is GET
    # @param [String] sub_url
    # @param [String] method
    # @param [String] data payload
    # @param [Hash] options for request
    def do_url sub_url, method = :get, data = nil, options = {}, client = client
      sub_url.slice! client.url
      fetcher = client[sub_url]
      fetcher.options.merge(options)
      begin
        return fetcher.get if method == :get
        fetcher.send method, data
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "Error fetching URL: #{sub_url}. See $logger for details"
      end
    end

    # Add resource to the catalog
    # @param [String] what
    # @param [String] message
    # @param [Symbol] method
    # @param [Hash] options
    def add what, message, method, options = {}
      h = options.delete(:headers) || headers(:xml)
      request = client[url_for(what, options)]
      request.options[:headers] = h
      begin
        return request.send method, message
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "Error adding #{what.inspect}. See logger for details"
      end

    end

    # Modify resource in the catalog
    # @param [String] what
    # @param [String] message
    # @param [Symbol] method
    # @param [Hash] options
    def modify what, message, method, options = {}
      h = options.delete(:headers) || headers(:xml)
      request = client[url_for(what, options)]
      request.options[:headers] = h
      $logger.debug "Modifying: \n #{message}"
      begin
        return request.send method, message
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "Error modifying #{what.inspect}. See $logger for details"
      end

    end

    # Purge resource from the catalog. Options can include recurse=true or false
    # @param [OrderedHash] what
    # @param [Hash] options
    def purge what, options
      request = client[url_for(what, options)]
      begin
        return request.delete
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "Error deleting #{what.inspect}. See $logger for details"
      end
    end

  end
end
