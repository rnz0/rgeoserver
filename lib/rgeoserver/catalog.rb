module RGeoServer
  # This class represents the main class of the data model.
  # Refer to 
  # - http://geoserver.org/display/GEOS/Catalog+Design
  # - http://docs.geoserver.org/stable/en/user/restconfig/rest-config-api.html#workspaces

  class Catalog
    include RGeoServer::RestApiClient
    
    attr_reader :config

    # @param [OrderedHash] options
    # @option options [String] :url
    # @option options [String] :user
    # @option options [String] :password
    def initialize options = {}
      @config = options
    end

    def to_s
      "Catalog: #{@config[:url]}"
    end

    def headers format
      sym = :xml || format.to_sym
      {:accept => sym, :content_type=> sym}
    end

    #== Resources
  
    # Shortcut to ResourceInfo.list to this catalog. See ResourceInfo#list
    # @param [RGeoServer::ResourceInfo.class] klass
    # @param [RGeoServer::Catalog] catalog
    # @param [Array<String>] names
    # @param [Hash] options
    # @param [bool] check_remote if already exists in catalog and cache it
    # @yield [RGeoServer::ResourceInfo] 
    def list klass, names, options, check_remote = false,  &block
      ResourceInfo.list klass, self, names, options, check_remote, &block
    end

    #= Workspaces

    # List of available workspaces
    # @return [Array<RGeoServer::Workspace>]
    def get_workspaces &block
      response = self.search :workspaces => nil 
      doc = Nokogiri::XML(response)
      workspaces = doc.xpath(Workspace.root_xpath).collect{|w| w.text.to_s }
      list Workspace, workspaces, {}, &block
    end
   
    # @param [String] workspace name
    # @return [RGeoServer::Workspace]
    def get_workspace workspace
      response = self.search :workspaces => workspace
      doc = Nokogiri::XML(response)
      name = doc.at_xpath(Workspace.member_xpath)
      return Workspace.new self, :name => name.text if name
    end

    # @return [RGeoServer::Workspace]
    def get_default_workspace
      response = self.search :workspaces => 'default'
      doc = Nokogiri::XML(response)
      name = doc.at_xpath("#{Workspace.member_xpath}/name/text()").to_s
      return Workspace.new self, :name => name
    end
 
    # Assign default workspace
    # @param [String] workspace name
    def set_default_workspace workspace
       raise TypeError, "Workspace name must be a string" unless workspace.instance_of? String
       dws = Workspace.new self, :name => 'default'
       dws.name = workspace # This creates a new workspace if name is new
       dws.save
       dws
    end
    
    # @param [String] store
    # @param [String] workspace
    def reassign_workspace store, workspace
      raise NotImplementedError
    end

    #= Layers

    # List of available layers
    # @return [Array<RGeoServer::Layer>]
    def get_layers &block
      response = self.search :layers => nil 
      doc = Nokogiri::XML(response)
      layers = doc.xpath(Layer.root_xpath).collect{|l| l.text.to_s }
      list Layer, layers, {}, &block
    end
   
    # @param [String] layer name
    # @return [RGeoServer::Layer]
    def get_layer layer
      response = self.search :layers => layer
      doc = Nokogiri::XML(response)
      name = doc.at_xpath("#{Layer.member_xpath}/name/text()").to_s
      return Layer.new self, :name => name
    end

    #= Styles (SLD Style Layer Descriptor)

    # List of available styles
    # @return [Array<RGeoServer::Style>]
    def get_styles &block
      response = self.search :styles => nil 
      doc = Nokogiri::XML(response)
      styles = doc.xpath(Style.root_xpath).collect{|l| l.text.to_s }
      list Style, styles, {}, &block
    end
   
    # @param [String] style name
    # @return [RGeoServer::Style]
    def get_style style
      response = self.search :styles => style
      doc = Nokogiri::XML(response)
      name = doc.at_xpath("#{Style.member_xpath}/name/text()").to_s
      return Style.new self, :name => name
    end


    #= Namespaces
 
    # List of available namespaces
    # @return [Array<RGeoServer::Namespace>]
    def get_namespaces 
      raise NotImplementedError
    end 

    # @return [RGeoServer::Namespace]
    def get_default_namespace 
      response = self.search :namespaces => 'default'
      doc = Nokogiri::XML(response)
      name = doc.at_xpath("#{Namespace.member_xpath}/prefix/text()").to_s
      uri = doc.at_xpath("#{Namespace.member_xpath}/uri/text()").to_s
      return Namespace.new self, :name => name, :uri => uri 
    end 

    def set_default_namespace id, prefix, uri 
      raise NotImplementedError
    end 

    #= Data Stores (Vector datasets)

    # List of vector based spatial data
    # @param [String] workspace
    # @return [Array<RGeoServer::DataStore>]
    def get_data_stores workspace = nil 
      ws = workspace.nil?? get_workspaces :  [get_workspace(workspace)] 
      ds = []
      ws.each{ |w| ds += w.data_stores if w.data_stores }  
      ds 
    end
     
    # @param [String] workspace
    # @param [String] datastore  
    # @return [RGeoServer::DataStore]
    def get_data_store workspace, datastore
      response = self.search({:workspaces => workspace, :name => datastore})
      doc = Nokogiri::XML(response)
      name = doc.at_xpath(DataStore.member_xpath)
      return DataStore.new self, workspace, name.text if name
    end
  
    # List of feature types
    # @param [String] workspace
    # @param [String] datastore 
    # @return [Array<RGeoServer::FeatureType>]
    def get_feature_types workspace, datastore
      raise NotImplementedError  
    end

    # @param [String] workspace
    # @param [String] datastore  
    # @param [String] featuretype_id  
    # @return [RGeoServer::FeatureType]
    def get_feature_type workspace, datastore, featuretype_id
      raise NotImplementedError  
    end    


    #= Coverages (Raster datasets) 
    
    # List of coverage stores
    # @param [String] workspace
    # @return [Array<RGeoServer::CoverageStore>]
    def get_coverage_stores workspace = nil
      ws = workspace.nil?? get_workspaces :  [get_workspace(workspace)] 
      cs = []
      ws.each{ |w| cs += w.coverage_stores if w.coverage_stores }  
      cs 
    end

    # @param [String] workspace
    # @param [String] coveragestore  
    # @return [RGeoServer::CoverageStore]
    def get_coverage_store workspace, coveragestore
      cs = CoverageStore.new self, :workspace => workspace, :name => coveragestore
      return cs.new?? nil : cs
    end

    def get_coverage workspace, coverage_store, coverage
      c = Coverage.new self, :workspace => workspace, :coverage_store => coverage_store, :name => coverage
      return c.new?? nil : c    
    end

    #= WMS Stores (Web Map Services)

    # List of WMS stores.
    # @param [String] workspace  
    # @return [Array<RGeoServer::WmsStore>]
    def get_wms_stores workspace = nil
      ws = workspace.nil?? get_workspaces :  [get_workspace(workspace)] 
      cs = []
      ws.each{ |w| cs += w.wms_stores if w.wms_stores }  
      cs 
    end

    # @param [String] workspace
    # @param [String] wmsstore  
    # @return [RGeoServer::WmsStore]
    def get_wms_store workspace, wmsstore
      response = self.search({:workspaces => workspace, :name => wmsstore})
      doc = Nokogiri::XML(response)
      name = doc.at_xpath(WmsStore.member_xpath)
      return WmsStore.new self, workspace, name.text if name
    end 

    #= Configuration reloading
    # Reloads the catalog and configuration from disk. This operation is used to reload GeoServer in cases where an external tool has modified the on disk configuration. This operation will also force GeoServer to drop any internal caches and reconnect to all data stores.
    def reload
      do_url 'reload', :put  
    end

    #= Resource reset
    # Resets all store/raster/schema caches and starts fresh. This operation is used to force GeoServer to drop all caches and stores and reconnect fresh to each of them first time they are needed by a request. This is useful in case the stores themselves cache some information about the data structures they manage that changed in the meantime.
    def reset
      do_url 'reset', :put
    end  
  
  end

end
