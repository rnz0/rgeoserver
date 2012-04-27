module RGeoServer
  # This class represents the main class of the data model.
  # Refer to 
  # - http://geoserver.org/display/GEOS/Catalog+Design
  # - http://docs.geoserver.org/stable/en/user/restconfig/rest-config-api.html#workspaces

  class Catalog
    include RGeoServer::RestApiClient
    include ActiveSupport::Benchmarkable
    
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

      #  r = RestClient::Resource.new 'http://localhost:8080/geoserver/rest/workspaces.xml', :user => 'admin', :password => 'geoserver', :headers => {:accept=>:xml, :content_type=> :xml}
    def client config = {}
      c = self.config.merge(config)
      @client ||= RestClient::Resource.new(c[:url], :user => c[:user], :password => c[:password], :headers => c[:headers])
    end

    def headers format
      sym = :xml || format.to_sym
      {:accept => sym, :content_type=> sym}
    end

    # List of workspaces available
    # @return [Array<RGeoServer::Workspace>]
    def get_workspaces
      response = self.search :workspaces => nil 
      doc = Nokogiri::XML(response)
      doc.xpath(Workspace.root_xpath).collect { |w| Workspace.new self, :name => w.text } 
    end
   
    # @param [String] workspace
    # @return [<RGeoServer::Workspace]
    def get_workspace workspace
      response = self.search :workspaces => workspace
      doc = Nokogiri::XML(response)
      name = doc.at_xpath(Workspace.member_xpath)
      return Workspace.new self, :name => name.text if name
    end

    # @return [<RGeoServer::Workspace]
    def get_default_workspace
      return Workspace.new self, :name => 'default'
    end
 
    def set_default_workspace
      raise NotImplementedError
    end
    
    # @param [String] store
    # @param [String] workspace
    def reassign_workspace store, workspace
      pass
    end

    # List of feature types
    # @return [Array<RGeoServer::Namespace>]
    # TODO: Implement when the stable release includes it
    def get_namespaces 
      raise NotImplementedError
    end 

    def get_default_namespace 
      raise NotImplementedError
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
      pass  

    end

    # @param [String] workspace
    # @param [String] datastore  
    # @param [String] featuretype_id  
    # @return [RGeoServer::FeatureType]
    def get_feature_type workspace, datastore, featuretype_id
      pass  
  
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
      response = self.search({:workspaces => workspace, :name => coveragestore})
      doc = Nokogiri::XML(response)
      name = doc.at_xpath(CoverageStore.member_xpath)
      return CoverageStore.new self, workspace, name.text if name
    end

    #= WMS Stores (Web Map Services)
    # TODO: Implement when the stable release includes it
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
    
  end

end
