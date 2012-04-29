
module RGeoServer

    class ResourceInfo

      include ActiveModel::Dirty
      extend ActiveModel::Callbacks

      define_model_callbacks :save, :destroy
      define_model_callbacks :initialize, :only => :after

      # mapping object parameters to profile elements
      OBJ_ATTRIBUTES = {:enabled => 'enabled'} 
      OBJ_DEFAULT_ATTRIBUTES = {:enabled => 'true'}

      define_attribute_methods OBJ_ATTRIBUTES.keys

      def self.update_attribute_accessors attributes
        attributes.each do |attribute, profile_name|
          class_eval <<-RUBY
          def #{attribute.to_s}
            @#{attribute} || profile['#{profile_name.to_s}'] || OBJ_DEFAULT_ATTRIBUTES[:#{attribute}]
          end

          def #{attribute.to_s}= val
            #{attribute.to_s}_will_change! unless val == #{attribute.to_s}
            @#{attribute.to_s} = val
          end
          RUBY
        end
      end

      def initialize options
        @new = true
      end

      def to_s
        "#{self.class.name}: #{name}"
      end

      def create_method
        self.class.create_method
      end

      def update_method
        self.class.update_method
      end

      # Modify or save the resource
      # @param options [Hash] 
      # @return [RGeoServer::ResourceInfo] 
      def save options = {}
        @previously_changed = changes
        @changed_attributes.clear
        run_callbacks :save do
          if new?
              @catalog.add(@route, message, create_method) 
              clear 
          else
            @catalog.modify({@route => @name}, message, update_method) #unless changes.empty? 
          end

          self
        end
      end
     
      # Purge resource from Geoserver Catalog
      # @param options [Hash] 
      # @return [RGeoServer::ResourceInfo] `self`
      def delete options = {} 
        run_callbacks :destroy do
          @catalog.purge({@route => @name}, options)  unless new?
          clear
          self
        end
      end
      
      # Check if this resource already exists
      # @return [Boolean]
      def new?
        profile
        @new
      end

      def clear
        @profile = nil
        @changed_attributes = {}
      end

      # Retrieve the resource profile as a hash and cache it 
      # @return [Hash]        
      def profile
        if @profile 
          return @profile
        end
    
        @profile ||= begin
          h = profile_xml_to_hash(@catalog.search @route => @name )
          @new = false
          h
        rescue RestClient::ResourceNotFound
          # The resource is new
          @new = true
          {}
        end.freeze 
      end

      def profile= profile_xml
        @profile = profile_xml_to_hash(profile_xml)
      end

      def profile_xml_to_ng profile_xml
        Nokogiri::XML(profile_xml).xpath(self.class.member_xpath)
      end
 
      def profile_xml_to_hash profile_xml
        doc = profile_xml_to_ng profile_xml 
        h = {'name' => doc.at_xpath('//name').text.strip, 'enabled' => @enabled }
        doc.xpath('//atom:link/@href', "xmlns:atom"=>"http://www.w3.org/2005/Atom" ).each{ |l| 
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
              Nokogiri::XML(response).xpath('//name/text()').collect{ |a| a.text }
            rescue RestClient::ResourceNotFound
              []
            end.freeze
          end
         }
        h  
      end

    end
end 
