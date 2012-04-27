require 'active_model'

module RGeoServer
  autoload :Config, "rgeoserver/config"
  autoload :Catalog, "rgeoserver/catalog"
  autoload :RestApiClient, "rgeoserver/rest_api_client"
  autoload :GeoServerUrlHelpers, "rgeoserver/geoserver_url_helpers"
  autoload :ResourceInfo, "rgeoserver/resource"
  autoload :Workspace, "rgeoserver/workspace"
  autoload :FeatureType, "rgeoserver/featuretype"
  autoload :Coverage, "rgeoserver/coverage"
  autoload :DataStore, "rgeoserver/datastore"
  autoload :CoverageStore, "rgeoserver/coveragestore"
  autoload :WmsStore, "rgeoserver/wmsstore"

  require 'restclient'
  require 'nokogiri'
  require 'time'
  require 'rgeoserver/version'

  def self.connect *args
    Catalog.new *args
  end

  def self.catalog
    @catalog ||= self.connect(self.default_config.geoserver)
  end 

  def self.catalog= catalog
    @catalog = catalog
  end

  def self.default_config *args, &block
    Config.configure *args, &block
  end


  class RGeoServerError < StandardError
  end

  class GeoServerInvalidRequest < RGeoServerError
  end

end
