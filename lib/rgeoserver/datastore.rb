
module RGeoServer

    class DataStore < ResourceInfo
  
      OBJ_ATTRIBUTES = {:enabled => "enabled", :catalog => "catalog", :workspace => "workspace", :name => "name", :connection_parameters => "connectionParameters"} 
      OBJ_DEFAULT_ATTRIBUTES = {:enabled => true, :catalog => nil, :workspace => nil, :name => nil, :connection_parameters => {}}
      define_attribute_methods OBJ_ATTRIBUTES.keys
      update_attribute_accessors OBJ_ATTRIBUTES
 
      attr_accessor :message
 
      @@r = Confstruct::Configuration.new(
          :route => "workspaces/%s/datastores",
          :root => "dataStores",
          :resource_name => "dataStore"
        )

      def self.root
        @@r.root
      end

      def self.method
        :put 
      end

      def self.resource_name
        @@r.resource_name
      end
 
      def self.root_xpath
        "//#{root}/#{resource_name}"
      end

      def self.member_xpath
        "//#{resource_name}"
      end

      def route
        @@r.route % @workspace.name
      end

      def update_route
        "#{route}/#{@name}"
      end

      def message
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.dataStore {
            xml.enabled 'true'
            xml.name @name
            xml.connectionParameters {  # this could be empty
              @connection_parameters.each_pair { |k,v| 
                xml.entry(:key => k) {
                  xml.text  v
                }
              } unless @connection_parameters.empty? 
            }
          }
        end
        builder.doc.to_xml
      end

      # @params [RGeoServer::Catalog] catalog
      # @params [RGeoServer::Workspace|String] workspace
      # @params [String] name
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

      def featuretypes
        profile["featureTypes"].collect{ |name|
          FeatureType.new @catalog, :workspace => @workspace, :data_store => self, :name => name
        }
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
            response = @catalog.fetch_url l.text
            Nokogiri::XML(response).xpath('//name/text()').collect{ |a| a.text }
          rescue RestClient::ResourceNotFound
            [] 
          end.freeze
          
         }
        h  
      end
    end
end 
