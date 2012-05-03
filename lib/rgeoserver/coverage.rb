
module RGeoServer
  # A coverage is a raster based data set which originates from a coverage store.
  class Coverage < ResourceInfo

    OBJ_ATTRIBUTES = {:catalog => "catalog", :name => "name", :workspace => "workspace", :enabled => "enabled" }
    OBJ_DEFAULT_ATTRIBUTES = {:catalog => nil, :workspace => nil, :coverage_store => nil, :name => nil, :enabled => "false" } 
   
    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    @@route = "workspaces/%s/coveragestores/%s/coverages"
    @@root  = "coverages"
    @@resource_name = "coverage"

    def self.root
      @@root
    end

    def self.create_method
      :put 
    end

    def self.update_method
      :put 
    end

    def self.member_xpath
      "//#{resource_name}"
    end

    def self.resource_name
      @@resource_name
    end

    def route
      @@route % [@workspace.name , @coverage_store.name]
    end


    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
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
        coverage_store = options[:coverage_store]
        if coverage_store.instance_of? String
          @coverage_store = CoverageStore.new @catalog, :workspace => @workspace, :name => coverage_store
        elsif coverage_store.instance_of? CoverageStore
          @coverage_store = coverage_store
        else
          raise "Not a valid coverage store"
        end

        @name = options[:name]
        @type = options[:type]
        @enabled = options[:enabled] || true
        @route = route
      end        
    end

    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml
      h = {
        "coverage_store" => @coverage_store.name,
        "workspace" => @workspace.name,
        "name" => doc.at_xpath('//name').text.strip,
        "nativeName" => doc.at_xpath('//nativeName').to_s,
        "title" => doc.at_xpath('//title').to_s,
        "supportedFormats" => doc.xpath('//supportedFormats/string').collect{ |t| t.to_s }
      }.freeze
      h  
    end


  end
end 
