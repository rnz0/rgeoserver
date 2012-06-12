
module RGeoServer
  # A coverage store is a source of spatial data that is raster based.
  class CoverageStore < ResourceInfo

    OBJ_ATTRIBUTES = {:catalog => 'catalog', :workspace => 'workspace', :url => 'url', :data_type => 'type', :name => 'name', :enabled => 'enabled', :description => 'description'}  
    OBJ_DEFAULT_ATTRIBUTES = {:catalog => nil, :workspace => nil, :url => '', :data_type => 'GeoTIFF', :name => nil, :enabled => 'true', :description=>nil}  
    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    @@route = "workspaces/%s/coveragestores"
    @@root = "coverageStores"
    @@resource_name = "coverageStore"

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

    def update_params name_route = @name 
      { :name => name_route, :workspace => @workspace.name }
    end

    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.coverageStore {
          xml.name @name  
          xml.workspace {
            xml.name @workspace.name
          }
          xml.enabled @enabled if (enabled_changed? || new?)
          xml.type_ @data_type if (data_type_changed? || new?)
          xml.description @description if (description_changed? || new?)
          xml.url @url if (url_changed? || new?)
        }
      end
      @message = builder.doc.to_xml 
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
        @route = route
      end        
    end

    def coverages &block
      self.class.list Coverage, @catalog, profile['coverages'], {:workspace => @workspace, :coverage_store => self}, check_remote = true, &block
    end

    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml 
      h = {
        'name' => doc.at_xpath('//name').text.strip, 
        'workspace' => @workspace.name, 
        'type' => doc.at_xpath('//type/text()').to_s,
        'enabled' => doc.at_xpath('//enabled/text()').to_s,
        'description' => doc.at_xpath('//description/text()').to_s,
        'url' => doc.at_xpath('//url/text()').to_s
      }.freeze
      h
    end

  end
end 
