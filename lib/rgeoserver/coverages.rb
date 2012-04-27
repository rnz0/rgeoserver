
module RGeoServer

    class CoverageStore < ResourceInfo

      OBJ_ATTRIBUTES = {:catalog => 'catalog', :workspace => 'workspace', :url => 'url', :data_type => 'type', :name => 'name', :enabled => 'enabled', :description => 'description'}  
      OBJ_DEFAULT_ATTRIBUTES = {:catalog => nil, :workspace => nil, :url => '', :data_type => 'GeoTIFF', :name => nil, :enabled => true, :description=>nil}  
      define_attribute_methods OBJ_ATTRIBUTES.keys
      update_attribute_accessors OBJ_ATTRIBUTES
  
      @@r = Confstruct::Configuration.new(
          #:route => "workspaces/%s/coveragestores",
          :route => "workspaces/%s/coveragestores/%s",
          #:root => "coverageStores",
          :root => "coverageStore",
          :resource_name => "coverageStore"
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
        #@@r.route % @workspace.name 
        @@r.route % [@workspace.name , @name]
      end

      def message
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.coverageStore {
            xml.name @name
            xml.enabled profile['enabled'] 
            xml.type_ @data_type if data_type_changed?
            xml.description @description if description_changed?
            xml.url @url if url_changed? 
          }
        end
        return builder.doc.to_xml 
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
          @route = route
        end        
      end

      def coverages
        profile[:coverages].collect{ |name|
          Coverage.new @catalog, :workspace => @workspace, :coverage_store => self, :name => name if name
        }
      end

      def profile_xml_to_ng1 profile_xml
        Nokogiri::XML(profile_xml).xpath(self.member_xpath)
      end 

      def profile_xml_to_hash profile_xml
        doc = profile_xml_to_ng profile_xml 
        {
          'name' => doc.at_xpath('//name').text.strip, 
          'workspace' => @workspace.name, 
          'type' => doc.at_xpath('//type/text()').to_s,
          'enabled' => doc.at_xpath('//enabled/text()').to_s,
          'description' => doc.at_xpath('//description/text()').to_s,
          'url' => doc.at_xpath('//url/text()').to_s
        }
      end

      def profile_xml_to_hash1 profile_xml
        doc = profile_xml_to_ng profile_xml 
        h = {:name => doc.at_xpath('//name').text.strip, :workspace => @workspace.name, :coverages => [] }
        doc.xpath('//coverages/atom:link/@href', "xmlns:atom"=>"http://www.w3.org/2005/Atom" ).each{ |l| 
          h[:coverages] << { 
            :name => l.parent.parent.at_xpath('//name/text()').to_s,
            :type => l.parent.parent.at_xpath('//type/text()').to_s,
            :enabled => l.parent.parent.at_xpath('//enabled/text()').to_s,
            :description => l.parent.parent.at_xpath('//description/text()').to_s,
            :url => l.parent.parent.at_xpath('//url/text()').to_s
          }
        }
        h  
      end
    end
end 
