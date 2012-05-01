
module RGeoServer

    class Workspace < ResourceInfo

      OBJ_ATTRIBUTES = {:enabled => 'enabled', :catalog => 'catalog', :name => 'name' }
      OBJ_DEFAULT_ATTRIBUTES = {:enabled => 'true', :catalog => nil, :name => nil }

      define_attribute_methods OBJ_ATTRIBUTES.keys
      update_attribute_accessors OBJ_ATTRIBUTES

      @@r = Confstruct::Configuration.new(:route => 'workspaces', :resource_name => 'workspace')
  
      def self.resource_name
        @@r.resource_name
      end

      def self.create_method 
        :post 
      end

      def self.update_method 
        :put 
      end
 
      def self.root_xpath
        "//#{@@r.route}/#{@@r.resource_name}"
      end

      def self.member_xpath
        "//#{resource_name}"
      end

      def route
        @@r.route  
      end

      def message
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.workspace { 
            xml.enabled @enabled if enabled_changed?
            xml.name @name 
          }
        end
        return builder.doc.to_xml 
      end

      # @param [RGeoServer::Catalog] catalog
      # @param [Hash] options
      def initialize catalog, options
        super({})
        _run_initialize_callbacks do
          @catalog = catalog
          @name = options[:name].strip
        end        
        @route = route
      end

      def data_stores &block
        self.class.list DataStore, @catalog, profile['dataStores'], {:workspace => self}, check_remote = true, &block
      end
    
      def coverage_stores &block
        self.class.list CoverageStore, @catalog, profile['coverageStores'], {:workspace => self}, check_remote = true, &block
      end

      def wms_stores &block
        self.class.list WmsStore, @catalog, profile['wmsStores'], {:workspace => self}, check_remote = true, &block
      end
 
      def profile_xml_to_hash profile_xml
        doc = profile_xml_to_ng profile_xml 
        h = {'name' => doc.at_xpath('//name').text.strip, 'enabled' => @enabled }
        doc.xpath('//atom:link/@href', "xmlns:atom"=>"http://www.w3.org/2005/Atom").each{ |l| 
          target = l.text.match(/([a-zA-Z]+)\.xml$/)[1]
          if !target.nil? && target != l.parent.parent.name.to_s.downcase
            begin
              h[l.parent.parent.name.to_s] << target
            rescue
              h[l.parent.parent.name.to_s] = []
            end
          else
            h[l.parent.parent.name.to_s] = begin
              response = @catalog.fetch_url l.text
              Nokogiri::XML(response).xpath('//name').collect{ |a| a.text.strip }
            rescue RestClient::ResourceNotFound
              []
            end.freeze
          end
         }
        h  
      end
 
    end
end 
