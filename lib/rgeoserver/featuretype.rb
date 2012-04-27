
module RGeoServer

    class FeatureType < ResourceInfo
  
      define_attribute_methods [:catalog, :workspace, :data_store, :name] 
  
      @@r = Confstruct::Configuration.new(
          :route => "workspaces/%s/datastores/%s/featuretypes",
          :root => "featureTypes",
          :resource_name => "featureType"
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
        @@r.route % [@workspace.name , @data_store.name ]
      end

      def xml options = nil
        <<-ds
          <dataStore>
          <enabled>true</enabled>
          <name>#{name}</name>
          <workspace><name>#{workspace_name}</name></workspace>
            <connectionParameters>
            <entry key="url">file:data/shapefiles/states.shp</entry>
            <entry key="namespace">http://www.openplans.org/topp</entry>
            </connectionParameters>
            <__default>false</__default>
            <featureTypes>
            <atom:link xmlns:atom="http://www.w3.org/2005/Atom" rel="alternate" href="http://localhost:8080/geoserver/rest/workspaces/topp/datastores/states_shapefile/featuretypes.xml" type="application/xml"/>
            </featureTypes>
         </dataStore>
        ds
      end

      def name
        @name      
      end

      def workspace
        @workspace
      end 

      def data_store
        @data_store
      end 

      def catalog
        @catalog
      end

      def workspace_name
        @workspace.name
      end

      def data_store_name
        @data_store.name
      end

      # @params [RGeoServer::Catalog] catalog
      # @params [Hash] options
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
          @enabled = options[:enabled] || true
          @route = route
        end        
      end

      def name= val
        name_will_change! unless val == @name
        @name = val
      end

      def workspace= val
        workspace_will_change! unless val == @workspace
        @workspace = val
      end

      def catalog= val
        catalog_will_change! unless val == @catalog
        @catalog = val
      end

      def profile_xml_to_hash profile_xml
        doc = profile_xml_to_ng profile_xml
        h = {
          :name => doc.at_xpath('//name').text.strip, 
          :workspace => workspace_name, 
          :nativeName => doc.at_xpath('//nativeName').text.to_s
        }.freeze  
        h  
      end


    end
end 
