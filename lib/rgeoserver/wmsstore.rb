
module RGeoServer

    class WmsStore < ResourceInfo
  
      define_attribute_methods [:catalog, :workspace, :name] 
  
      @@r = Confstruct::Configuration.new(
          :route => "workspaces/%s/wmsstores",
          :root => "wmsStores",
          :resource_name => "wmsStore"
        )

      def self.root
        @@r.root
      end

      def self.create_method
        :put 
      end

      def self.update_method
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

      def xml options = nil
        <<-cs
          <wmsStore>
          <enabled>true</enabled>
          <name>#{name}</name>
          <workspace><name>#{workspace_name}</name></workspace>
         </wmsStore>
        cs
      end

      def name
        @name      
      end

      def workspace
        @workspace
      end 

      def catalog
        @catalog
      end

      def workspace_name
        @workspace.name
      end

      # @param [RGeoServer::Catalog] catalog
      # @param [RGeoServer::Workspace|String] workspace
      # @param [String] name
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

    end
end 
