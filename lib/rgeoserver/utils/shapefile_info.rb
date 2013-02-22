require 'rgeo'
require 'rgeo/shapefile'
require 'zip/zip'

module RGeoServer
  class ShapefileInfo
    class ShapefileInfoGeometryNotExpected < StandardError
      def initialize geometry_type
        @geometry_type = geometry_type
      end

      def message
        "The geometry type %s was not expected." % geometry_type
      end
    end

    attr_reader :file_path

    def initialize file_path
      @file_path = file_path
    end

    def bounds
      resource_init

      bbox = BoundingBox.new
      RGeo::Shapefile::Reader.open(@shp_path) do |shp|
        shp.each do |record|
          geometry = record.geometry
          envelope = geometry.envelope
          envelope_type = envelope.geometry_type
          points = case envelope_type
                   when RGeo::Feature::Point
                     [envelope]
                   when RGeo::Feature::Polygon
                     envelope.exterior_ring.points
                   else
                     raise ShapefileInfoGeometryNotExpected, envelope_type
                   end
          points.each { |point| bbox.add point.x, point.y }
        end
      end

      resource_destroy

      bbox.expand if [bbox.minx, bbox.miny] == [bbox.maxx, bbox.maxy]

      bbox
    end

    def srid
      resource_init

      srid = 0
      RGeo::Shapefile::Reader.open(@shp_path) do |shp|
        srid = shp.factory.srid
      end

      resource_destroy

      srid
    end

    private
    def tmp_dir
      @tmp_dir ||= Dir.mktmpdir
    end

    def resource_init
      if @file_path =~ /\.zip$/i
        Zip::ZipFile.open(@file_path) do |zipfile|
          zipfile.glob('**/**').each do |entry_name|
            dest_path = [tmp_dir, entry_name].join(File::SEPARATOR)
            @shp_path = dest_path if entry_name.name =~ /\.shp$/i
            zipfile.extract entry_name, dest_path
          end
        end
      else
        @shp_path = @file_path
      end
    end

    def resource_destroy
      FileUtils.rm_rf [tmp_dir]
      @shp_path = nil
      @tmp_dir = nil
    end
  end
end
