
module RGeoServer
  # A coverage is a raster based data set which originates from a coverage store.
  class Coverage < ResourceInfo

    OBJ_ATTRIBUTES = {:catalog => "catalog", :workspace => "workspace", :coverage_store => "coverage_store", :name => "name", :title => "title", :abstract => "abstract", :metadata_links => "metadataLinks" }
    OBJ_DEFAULT_ATTRIBUTES = {:catalog => nil, :workspace => nil, :coverage_store => nil, :name => nil, :title => nil, :abstract => nil,  :metadata_links => [] } 
   
    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    @@route = "workspaces/%s/coveragestores/%s/coverages"
    @@root  = "coverages"
    @@resource_name = "coverage"

    def self.root
      @@root
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

    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.coverage {
          xml.name @name
          xml.title @title 
          unless new?
            xml.nativeName @name
            xml.abstract @abtract if abstract_changed?
            xml.metadataLinks {
              @metadata_links.each{ |m|
                xml.metadataLink {
                  xml.type_ m['type']
                  xml.metadataType m['metadataType']
                  xml.content m['content']
                }
              }
            } if metadata_links_changed?
          end
        }
      end
      @message = builder.doc.to_xml 
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
        @title = options[:title]
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
        "abstract" => doc.at_xpath('//abstract').to_s, 
        "supportedFormats" => doc.xpath('//supportedFormats/string').collect{ |t| t.to_s },
        "metadataLinks" => doc.xpath('//metadataLinks/metadataLink').collect{ |m| 
          { 
            'type' => m.at_xpath('//type/text()').to_s, 
            'metadataType' => m.at_xpath('//metadataType/text()').to_s,
            'content' => m.at_xpath('//content').text.strip
          } 
        }
      }.freeze
      h  
    end


  end
end 
