
module RGeoServer
  # A layer group is a grouping of layers and styles that can be accessed as a single layer in a WMS GetMap request. A Layer group is often referred to as a "base map".
  class LayerGroup < ResourceInfo

    OBJ_ATTRIBUTES = {:catalog => 'catalog', :name => 'name', :workspace => 'workspace', :layers => 'layers', :styles => 'styles', :bounds => 'bounds', :metadata => 'metadata' }
    OBJ_DEFAULT_ATTRIBUTES = {:catalog => nil, :name => nil, :workspace => nil, :layers => nil, :styles => [], :bounds => {'minx'=>nil, 'miny' =>nil, 'maxx'=>nil, 'maxy'=>nil, 'crs' =>nil}, :metadata => {} }

    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    @@xml_list_node = "layerGroups"
    @@xml_node = "layerGroup"

    @@route = "layergroups"
    @@resource_name = "layerGroup"

    def self.resource_name
      @@resource_name
    end

    def self.root_xpath
      "//#{@@xml_list_node}/#{@@xml_node}"
    end

    def self.member_xpath
      "//#{@@xml_node}"
    end

    def route
      if @workspace
        "workspaces/#{@workspace.name}/#{@@route}"
      else
        @@route
      end
    end

    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.layerGroup {
          xml.name @name
          xml.workspace {
            xml.name workspace.name
          } unless workspace.nil?
          xml.layers {
            layers.each { |l|
              xml.layer {
                xml.name l.name
              }
            }
          } unless layers.nil?
          xml.styles {
            (0...layers.count).each { |l_idx|
              xml.style {
                xml.name (styles && styles[l_idx] || nil) && (styles[l_idx].name)
              }
            } unless layers.nil?
          }
          xml.bounds {
            xml.minx bounds['minx'] if bounds['minx']
            xml.miny bounds['miny'] if bounds['miny']
            xml.maxx bounds['maxx'] if bounds['maxx']
            xml.maxy bounds['maxy'] if bounds['maxy']
            xml.crs bounds['crs'] if bounds['crs']
          } if valid_bounds?
        }
      end
      return builder.doc.to_xml
    end

    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
    # @option options [String] :name
    def initialize catalog, options
      super({})
      _run_initialize_callbacks do
        @catalog = catalog
        @name = options[:name].strip
        workspace = options[:workspace]
        if workspace.instance_of? String
          @workspace = @catalog.get_workspace(workspace)
        elsif workspace.instance_of? Workspace
          @workspace = workspace
        end
      end
      @route = route
    end

    # @param [Array<RGeoServer::Style>] sl list of styles
    def styles= sl
      if sl.inject(true){|t,s| t && s.is_a?(RGeoServer::Style)}
        styles_will_change! unless sl == styles
        @styles = sl
      else
        raise 'Unknown list of styles'
      end
    end

    def styles
      @styles ||= begin
                    unless profile['styles'].empty?
                      return profile['styles'].each{ |s| RGeoServer::Style.new @catalog, :name => s.name }
                    else
                      nil
                    end
                  rescue Exception => e
                    nil
                  end
    end

    # @param [Array<RGeoServer::Layer>] ll list of layers
    def layers= ll
      if ll.inject(true){ |t,l| t && l.is_a?(RGeoServer::Layer) }
        layers_will_change! unless ll == layers
        @layers = ll
      else
        raise 'Unknown list of layers'
      end
    end

    def layers
      @layers ||=
        unless @layers
          begin
            unless profile['layers'].empty?
              profile['layers'].map{ |s| RGeoServer::Layer.new @catalog, :name => s }
            else
              []
            end
          rescue Exception => e
            []
          end
        end
    end

    def workspace
      if new?
        return @workspace
      else
        return RGeoServer::Workspace.new @catalog, name: profile['workspace']
      end
    end

    def valid_bounds?
      bounds && !([bounds['minx'], bounds['miny'], bounds['maxx'], bounds['maxy'], bounds['crs']].compact.empty?)
    end

    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml
      name = doc.at_xpath('//name/text()').to_s

      h = {
        "name" => name,
        "workspace" => doc.xpath('//workspace/name/text()').to_s,
        "layers" => doc.xpath('//published[@type="layer"]/name/text()').collect{|l| l.to_s},
        "styles" => doc.xpath('//styles/style/name/text()').collect{|s| s.to_s},
        "bounds" => {
          "minx" => doc.at_xpath('//bounds/minx/text()').to_s.to_f,
          "maxx" => doc.at_xpath('//bounds/maxx/text()').to_s.to_f,
          "miny" => doc.at_xpath('//bounds/miny/text()').to_s.to_f,
          "maxy" => doc.at_xpath('//bounds/maxy/text()').to_s.to_f,
          "crs" => doc.at_xpath('//bounds/crs/text()').to_s
        },
        "metadata" => doc.xpath('//metadata/entry').inject({}){ |h, e| h.merge(e['key']=> e.text.to_s) }
      }.freeze
      h
    end

  end
end
