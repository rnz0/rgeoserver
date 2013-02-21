require 'active_model'
require 'yaml'
require 'confstruct'

module RGeoServer
  autoload :Config, "rgeoserver/config"
  autoload :Catalog, "rgeoserver/catalog"
  autoload :RestApiClient, "rgeoserver/rest_api_client"
  autoload :GeoServerUrlHelpers, "rgeoserver/geoserver_url_helpers"
  autoload :ResourceInfo, "rgeoserver/resource"
  autoload :Namespace, "rgeoserver/namespace"
  autoload :Workspace, "rgeoserver/workspace"
  autoload :FeatureType, "rgeoserver/featuretype"
  autoload :Coverage, "rgeoserver/coverage"
  autoload :DataStore, "rgeoserver/datastore"
  autoload :CoverageStore, "rgeoserver/coveragestore"
  autoload :WmsStore, "rgeoserver/wmsstore"
  autoload :Style, "rgeoserver/style"
  autoload :Layer, "rgeoserver/layer"
  autoload :LayerGroup, "rgeoserver/layergroup"

  autoload :BoundingBox, "rgeoserver/utils/boundingbox"
  autoload :ShapefileInfo, "rgeoserver/utils/shapefile_info"

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
