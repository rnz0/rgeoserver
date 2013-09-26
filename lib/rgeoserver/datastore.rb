require 'zip'

module RGeoServer
  # A data store is a source of spatial data that is vector based. It can be a file in the case of a Shapefile, a database in the case of PostGIS, or a server in the case of a remote Web Feature Service.
  class DataStore < ResourceInfo

    class DataStoreAlreadyExists < StandardError
      def initialize(name)
        @name = name
      end

      def message
        "The DataStore '#{@name}' already exists and can not be replaced."
      end
    end

    class DataTypeNotExpected < StandardError
      def initialize(data_type)
        @data_type = data_type
      end

      def message
        "The DataStore does not not accept the data type '#{@data_type}'."
      end
    end

    OBJ_ATTRIBUTES = {:enabled => "enabled", :catalog => "catalog", :workspace => "workspace", :name => "name", :connection_parameters => "connection_parameters"}
    OBJ_DEFAULT_ATTRIBUTES = {:enabled => 'true', :catalog => nil, :workspace => nil, :name => nil, :connection_parameters => {}}
    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    attr_accessor :message

    @@route = "workspaces/%s/datastores"
    @@root = "dataStores"
    @@resource_name = "dataStore"

    def self.root
      @@root
    end

    def self.resource_name
      @@resource_name
    end

    def self.root_xpath
      "//#{root}/#{resource_name}"
    end

    def self.member_xpath
      "//#{resource_name}"
    end

    def route
      @@route % @workspace.name
    end

    def update_route
      "#{route}/#{@name}"
    end

    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.dataStore {
          xml.name @name
          xml.enabled enabled
          xml.connectionParameters {  # this could be empty
            connection_parameters.each_pair { |k,v|
              xml.entry(:key => k) {
                xml.text v
              }
            } unless connection_parameters.nil? || connection_parameters.empty?
          }
        }
      end
      builder.doc.to_xml
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

    def featuretypes &block
      self.class.list FeatureType, @catalog, profile['featureTypes'], {:workspace => @workspace, :data_store => self}, check_remote = true, &block
    end

    # @param [String] file_path
    # @param [Hash] options { data_type: [:shapefile] }. optional
    def upload_file file_path, options = {}
      raise DataStoreAlreadyExists, @name unless new?

      options = options.dup

      options[:publish] = true unless options.include? :publish

      publish = options.delete :publish
      data_type = options.delete(:data_type) || :shapefile
      data_type = data_type.to_sym

      upload_url_suffix = case data_type
                          when :shapefile then "#{update_route}/file.shp"
                          else
                            raise DataTypeNotExpected, data_type
                          end

      tmp_zip_path = File.join Dir.tmpdir, "#{@name}.zip"
      while File.exists? tmp_zip_path
        tmp_zip_path = File.join Dir.tmpdir, ("#{@name}.%.3d.zip" % (rand*1000))
      end
      FileUtils.cp file_path, tmp_zip_path
      Zip::File.open(tmp_zip_path) do |zip_file|
        zip_file.glob('**/**') do |entry|
          extname = File.extname entry.name
          extry_name_new = "#{@name}#{extname}"
          zip_file.rename entry, extry_name_new unless extry_name_new == entry.name
        end
      end

      @catalog.client[upload_url_suffix].put File.read(tmp_zip_path), content_type: 'application/zip'

      FileUtils.rm_rf [tmp_zip_path]

      clear

      ft = featuretypes.first

      if publish
        shp_info = ShapefileInfo.new file_path
        ft.native_bounds['minx'], ft.native_bounds['miny'], ft.native_bounds['maxx'], ft.native_bounds['maxy'] =
          shp_info.bounds.to_a
        ft.projection_policy = :force
        ft.save
      else
        ft.delete recurse: true
      end

      clear

      self
    end

    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml
      h = {
        "name" => doc.at_xpath('//name').text.strip,
        "enabled" => doc.at_xpath('//enabled/text()').to_s,
        "connection_parameters" => doc.xpath('//connectionParameters/entry').inject({}){ |h, e| h.merge(e['key']=> e.text.to_s) }
      }
      doc.xpath('//featureTypes/atom:link/@href', "xmlns:atom"=>"http://www.w3.org/2005/Atom" ).each{ |l|
        h["featureTypes"] = begin
                              response = @catalog.do_url l.text
                              Nokogiri::XML(response).xpath('//name/text()').collect{ |a| a.text.strip }
                            rescue RestClient::ResourceNotFound
                              []
                            end.freeze
      }
      h
    end
  end
end
