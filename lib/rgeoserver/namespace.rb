
module RGeoServer
  # A namespace is a uniquely identifiable grouping of feature types. A namespaces is identified by a prefix and a uri.
  class Namespace < ResourceInfo

    OBJ_ATTRIBUTES = {:enabled => 'enabled', :catalog => 'catalog', :name => 'prefix', :uri => 'uri' }
    OBJ_DEFAULT_ATTRIBUTES = {:enabled => 'true', :catalog => nil, :name => nil }

    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    @@route = "namespaces"
    @@resource_name = "namespace"

    def self.resource_name
      @@resource_name
    end

    def self.root_xpath
      "//#{@@route}/#{@@resource_name}"
    end

    def self.member_xpath
      "//#{resource_name}"
    end

    def route
      @@route  
    end

    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.namespace { 
          xml.prefix @name 
          xml.uri @uri
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
        @uri = options[:uri] if options[:uri]
      end        
      @route = route
    end

    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml 
      h = {
        'name' => doc.at_xpath('//namespace/prefix/text()').to_s,
        'uri' => doc.at_xpath('//namespace/uri/text()').to_s
      }.freeze
      h  
    end

  end
end 
