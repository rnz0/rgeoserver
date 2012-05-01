
module RGeoServer

    class Layer < ResourceInfo

      OBJ_ATTRIBUTES = {:enabled => 'enabled', :catalog => 'catalog', :name => 'name', :default_style => 'default_style', :alternative_style => 'alternative_style' }
      OBJ_DEFAULT_ATTRIBUTES = {:enabled => 'true', :catalog => nil, :name => nil, :default_style => nil, :alternative_styles => [] }

      define_attribute_methods OBJ_ATTRIBUTES.keys
      update_attribute_accessors OBJ_ATTRIBUTES

      @@r = Confstruct::Configuration.new(:route => 'layers', :resource_name => 'layer')
  
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
          xml.layer { 
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

      def resource
        unless profile['resource'].empty?
          data_type = profile['resource']['type']
          workspace = profile['resource']['workspace']
          name = profile['resource']['name']
          store = profile['resource']['store']

          case data_type
          when 'coverage'
            return RGeoServer::Coverage.new @catalog, :workspace => workspace, :coverage_store => store, :name => name
          when 'featureType'
            return RGeoServer::FeatureType.new @catalog, :workspace => workspace, :data_store => store, :name => name
          else
            nil  
          end
        else
          nil
        end
      end

      def styles &block
        puts profile['styles']
        self.class.list Style, @catalog, profile['styles'], {:layer => self}, check_remote = true, &block
      end

      def profile_xml_to_hash profile_xml
        doc = profile_xml_to_ng profile_xml
        name = doc.at_xpath('//name/text()').text.strip
        link = doc.at_xpath('//resource//atom:link/@href', "xmlns:atom"=>"http://www.w3.org/2005/Atom").text.strip
        workspace, _, store = link.match(/workspaces\/(.*?)\/(.*?)\/(.*?)\/(.*?)\/#{name}.xml$/).to_a[1,3]

        h = {
          "name" => name, 
          "path" => doc.at_xpath('//path/text()').to_s,
          "defaultstyle" => doc.at_xpath('//defaultStyle/name/text()').to_s,
          "styles" => doc.xpath('//styles/style/name/text()').collect{ |s| s.to_s},
          "type" => doc.at_xpath('//type/text()').to_s,
          "enabled" => doc.at_xpath('//enabled/text()').to_s,
          "attribution" => { 
            "logoWidth" => doc.at_xpath('//attribution/logoWidth/text()').to_s,
            "logoHeight" => doc.at_xpath('//attribution/logoHeight/text()').to_s
          },
          "resource" => {
            "type" => doc.at_xpath('//resource/@class').to_s,
            "name" => doc.at_xpath('//resource/name/text()').to_s,
            "store" => store,
            "workspace" => workspace 
          },
          "metadata" => doc.xpath('//metadata/entry').inject({}){ |h, e| h.merge(e['key']=> e.text.to_s) } 
        }.freeze
        h  
      end
 
    end
end 
