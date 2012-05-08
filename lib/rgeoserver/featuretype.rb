
module RGeoServer
  # A feature type is a vector based spatial resource or data set that originates from a data store. In some cases, like Shapefile, a feature type has a one-to-one relationship with its data store. In other cases, like PostGIS, the relationship of feature type to data store is many-to-one, with each feature type corresponding to a table in the database.
  class FeatureType < ResourceInfo
    OBJ_ATTRIBUTES = {:catalog => "catalog", :name => "name", :workspace => "workspace", :enabled => "enabled", :metadata_links => "metadataLinks", :title => "title", :abstract => "abstract" }
    OBJ_DEFAULT_ATTRIBUTES = {:catalog => nil, :workspace => nil, :coverage_store => nil, :name => nil, :enabled => "false", :metadata_links => [], :title => nil, :abtract => nil } 
   
    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    @@route = "workspaces/%s/datastores/%s/featuretypes"
    @@root = "featureTypes"
    @@resource_name = "featureType"

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
      @@route % [@workspace.name , @data_store.name ]
    end

    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.featureType {
          xml.name @name
          unless new?
            xml.title @title
            xml.abstract @abtract if abstract_changed?
            xml.store(:class => 'featureType') {
              xml.name @data_store.name
            } 
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
        data_store = options[:data_store]
        if data_store.instance_of? String
          @data_store = DataStore.new @catalog, :workspace => @workspace, :name => data_store
        elsif data_store.instance_of? DataStore
          @data_store = data_store
        else
          raise "Not a valid data store"
        end

        @name = options[:name].strip
        @route = route
      end        
    end


    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml
      h = {
        "name" => doc.at_xpath('//name').text.strip, 
        "title" => doc.at_xpath('//title').to_s,
        "abstract" => doc.at_xpath('//abstract').to_s, 
        "workspace" => @workspace.name, 
        "nativeName" => doc.at_xpath('//nativeName').to_s,
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
