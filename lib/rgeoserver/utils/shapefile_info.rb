require 'rgeo'
require 'rgeo/shapefile'

module RGeoServer
  class ShapefileInfo
    attr_reader :file_path

    def initialize file_path
      @file_path = file_path
    end

    def bounds
      bbox = BoundingBox.new
      RGeo::Shapefile::Reader.open(@file_path) do |shp|
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
      bbox
    end

    def srid
      srid = 0
      RGeo::Shapefile::Reader.open(@file_path) do |shp|
        srid = shp.factory.srid
      end
      srid
    end
  end
end
