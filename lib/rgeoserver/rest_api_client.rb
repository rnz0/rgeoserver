
require 'logger'
$logger = Logger.new(STDOUT)
$logger.level = Logger::WARN


module RGeoServer
  module RestApiClient

    include RGeoServer::GeoServerUrlHelpers
    include ActiveSupport::Benchmarkable

    def client config = {}
      c = self.config.merge(config)
      @client ||= RestClient::Resource.new(c[:url], :user => c[:user], :password => c[:password], :headers => c[:headers])
    end

    def headers format
      sym = :xml || format.to_sym
      {:accept => sym, :content_type=> sym}
    end

    # Search a resource in the catalog
    # @param [OrderedHash] what
    # @param [Hash] options
    def search what, options = {}
      resources = client[url_for(what, options)]
      resources.options[:headers] ||= headers(:xml)
      begin
        return resources.get
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "Error listing #{what.inspect}. See $logger for details"
      end
    end

    # Fetch an arbitrary URL within the catalog
    # @param [String] url
    def fetch_url url
      url.slice! client.url
      fetcher = client[url]
      fetcher.options[:headers] ||= headers(:xml)
      begin  
        return fetcher.get
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "Error fetching URL: #{url}. See $logger for details"
      end

    end

    # Add resource to the catalog
    # @param [String] what
    # @param [String] message
    # @param [Symbol] method
    def add what, message, method = :post
      request = client[url_for(what)]
      request.options[:headers] ||= headers(:xml)
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
    def modify what, message
      request = client[url_for(what, {})]
      request.options[:headers] ||= headers(:xml) 
      $logger.debug "Modifying: \n #{message}"
      begin 
        return request.put message
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
