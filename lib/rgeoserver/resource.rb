
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

      # Generic object construction iterator
      # @param [RGeoServer::ResourceInfo.class] klass
      # @param [RGeoServer::Catalog] catalog
      # @param [Array<String>] names
      # @param [Hash] options
      # @param [bool] check_remote if already exists in catalog and cache it
      # @yield [RGeoServer::ResourceInfo] 
      def self.list klass, catalog, names, options, check_remote = false, &block
        if names.nil?
          return []
        elsif !block_given?
          to_enum(:list, klass, catalog, names, options).to_a unless block_given?
        else 
          (names.is_a?(Array)? names : [names]).each { |name|
            obj = klass.new catalog, options.merge(:name => name)
            obj.new? if check_remote  
            block.call(obj)
          }        
        end 
      end

      def initialize options
        @new = true
      end

      def to_s
        "#{self.class.name}: #{name}"
      end
  
      # Return full name of resource with namespace prefix
      def prefixed_name
        return "#{workspace.name}:#{name}" if self.respond_to?(:workspace)
        raise "Workspace is not defined for this resource"
      end

      def create_method
        :post 
      end

      def update_method
        :put 
      end
  
      # We pass the old name "name_route" in case the name of the resource is being edited
      # Child classes should implement this
      def update_params name_route = name
        { self.class.resource_name.downcase.to_sym => name_route }  
      end

      # Modify or save the resource
      # @param [Hash] options / query parameters
      # @return [RGeoServer::ResourceInfo] 
      def save options = {}
        @previously_changed = changes
        @changed_attributes.clear
        run_callbacks :save do
          unless @previously_changed[:name].nil?
            old_name, new_name = @previously_changed[:name]
            name_route = old_name if old_name != new_name
            update = true
          else
            name_route = name
            update = false
          end
          if !update && new?
            if self.respond_to?(:create_route)
              raise "Resource cannot be created directly" if create_route.nil?
              route = create_route
            else
              route = {@route => nil}
            end
            
            options = create_options.merge(options) if self.respond_to?(:create_options)
            @catalog.add(route, message, create_method, options) 
            clear 
          else
            options = update_params(name_route).merge(options)
            route = {@route => name_route}
            @catalog.modify(route, message, update_method, options) #unless changes.empty? 
          end

          self
        end
      end
     
      # Purge resource from Geoserver Catalog
      # @param [Hash] options
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
        raise NotImplementedError    
      end

    end
end 
