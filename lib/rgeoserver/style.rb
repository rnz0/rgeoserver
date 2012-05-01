
module RGeoServer

    class Style < ResourceInfo

      OBJ_ATTRIBUTES = {:catalog => 'catalog', :name => 'name', :sld_version => 'sldVersion', :filename => 'filename' }
      OBJ_DEFAULT_ATTRIBUTES = {:catalog => nil, :name => nil, :sld_version => nil, :filename => '' }

      define_attribute_methods OBJ_ATTRIBUTES.keys
      update_attribute_accessors OBJ_ATTRIBUTES

      @@r = Confstruct::Configuration.new(:route => 'styles', :resource_name => 'style', :sld_namespace => 'http://www.opengis.net/sld')
  
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
    
      def sld_namespace
        @@r.sld_namespace
      end

      def message
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.layer { 
            xml.name @name 
            xml.sldVersion {
              xml.version @sld_version
            }
            xml.filename @filename
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
  
      # Obtain all layers that use this style.
      # WARNING: This will be slow and inneficient when the list of all layers is too long.
      def layers &block
        return to_enum(:layers).to_a unless block_given?

        @catalog.get_layers do |l|
          yield l if ([l.profile['default_style']]+l.profile['alternate_styles']).include? @name
        end 
      end

      def profile_xml_to_hash profile_xml
        doc = profile_xml_to_ng profile_xml
        h = {
          'name' => doc.at_xpath('//name').text.strip, 
          'sld_version' => doc.at_xpath('//sldVersion/version/text()').to_s,
          'filename' => doc.at_xpath('//filename/text()').to_s,
          'sld' => begin
            response = @catalog.search({:styles => @name}, options = {:format => 'sld'})
  #doc.xpath('//atom:link/@href', "xmlns:atom"=>"http://www.w3.org/2005/Atom" 
            sld_doc = Nokogiri::XML(response)
            {
              'sld_name' => sld_doc.at_xpath('//sld:NamedLayer/sld:UserStyle/sld:Name/text()', 'xmlns:sld' => sld_namespace).to_s,
              'sld_title' => sld_doc.at_xpath('//sld:NamedLayer/sld:UserStyle/sld:Title/text()', 'xmlns:sld' => sld_namespace).to_s
            }
          rescue RestClient::ResourceNotFound
            {}
          end
        }.freeze 
        h 
      end
 
    end
end 
