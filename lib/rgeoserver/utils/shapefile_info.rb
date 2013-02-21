require 'rgeo'
require 'rgeo/shapefile'
require 'zip/zip'

module RGeoServer
  class ShapefileInfo
    attr_reader :file_path

    @@epsilon = 0.001

    def self.epsilon
      @@epsilon
    end

    def self.epsilon= value
      @@epsilon = value
    end

    def initialize file_path
      @file_path = file_path
    end

    def bounds
      resource_init

      bbox = BoundingBox.new
      RGeo::Shapefile::Reader.open(@shp_path) do |shp|
        shp.each do |record|
          geometry = record.geometry
          points = case geometry.envelope.geometry_type
                   when RGeo::Feature::Point
                     [geometry.envelope]
                   when RGeo::Feature::Polygon
                     geometry.envelope.exterior_ring.points
                   end
          points.each { |point| bbox.add point.x, point.y }
        end
      end

      resource_destroy

      if [bbox.minx, bbox.miny] == [bbox.maxx, bbox.maxy]
        bbox.minx -= @@epsilon
        bbox.miny -= @@epsilon
        bbox.maxx += @@epsilon
        bbox.maxy += @@epsilon
      end

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
      end
    end

    def resource_destroy
      FileUtils.rm_rf [tmp_dir]
      @shp_path = nil
      @tmp_dir = nil
    end
  end
end
