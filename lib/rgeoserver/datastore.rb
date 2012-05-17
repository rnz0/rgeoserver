
module RGeoServer
  # A data store is a source of spatial data that is vector based. It can be a file in the case of a Shapefile, a database in the case of PostGIS, or a server in the case of a remote Web Feature Service.
  class DataStore < ResourceInfo

    OBJ_ATTRIBUTES = {:enabled => "enabled", :catalog => "catalog", :workspace => "workspace", :name => "name", :connection_parameters => "connectionParameters"} 
    OBJ_DEFAULT_ATTRIBUTES = {:enabled => 'true', :catalog => nil, :workspace => nil, :name => nil, :connection_parameters => {}}
    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    attr_accessor :message

    @@route = "workspaces/%s/datastores"
    @@root = "dataStores"
    @@resource_name = "dataStore"

    def self.root
      @@root
    end

    def self.resource_name
      @@resource_name
    end

    def self.root_xpath
      "//#{root}/#{resource_name}"
    end

    def self.member_xpath
      "//#{resource_name}"
    end

    def route
      @@route % @workspace.name
    end

    def update_route
      "#{route}/#{@name}"
    end

    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.dataStore {
          xml.name @name
          xml.enabled @enabled
          xml.connectionParameters {  # this could be empty
            @connection_parameters.each_pair { |k,v| 
              xml.entry(:key => k) {
                xml.text v
              }
            } unless @connection_parameters.empty? 
          }
        }
      end
      builder.doc.to_xml
    end

    # @param [RGeoServer::Catalog] catalog
    # @param [RGeoServer::Workspace|String] workspace
    # @param [String] name
    def initialize catalog, options 
      super({})
      _run_initialize_callbacks do
        @catalog = catalog
        workspace = options[:workspace] || 'default'
        if workspace.instance_of? String
          @workspace = @catalog.get_workspace(workspace)
        elsif workspace.instance_of? Workspace
          @workspace = workspace
        else
          raise "Not a valid workspace"
        end
        @name = options[:name].strip
        @connection_parameters = options[:connection_parameters] || {}
        @route = route
      end        
    end

    def featuretypes &block
      self.class.list FeatureType, @catalog, profile['featureTypes'], {:workspace => @workspace}, check_remote = true, &block
    end

    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml
      h = {
        "name" => doc.at_xpath('//name').text.strip, 
        "enabled" => doc.at_xpath('//enabled/text()').to_s,
        "connectionParameters" => doc.xpath('//connectionParameters/entry').inject({}){ |h, e| h.merge(e['key']=> e.text.to_s) } 
      }
      doc.xpath('//featureTypes/atom:link/@href', "xmlns:atom"=>"http://www.w3.org/2005/Atom" ).each{ |l| 
        h["featureTypes"] = begin
          response = @catalog.do_url l.text
          Nokogiri::XML(response).xpath('//name/text()').collect{ |a| a.text.strip }
        rescue RestClient::ResourceNotFound
          [] 
        end.freeze
        
       }
      h  
    end
  end
end 
