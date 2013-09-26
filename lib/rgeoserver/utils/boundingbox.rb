require 'rgeo'

module RGeoServer
  class BoundingBox
    attr_accessor :minx, :miny, :maxx, :maxy

    @@epsilon = 0.0001

    def self.epsilon
      @@epsilon
    end

    def self.epsilon= value
      @@epsilon = value
    end

    def initialize
      reset
    end

    def reset
      @minx = @miny = @maxx = @maxy = 0.0
      @empty = true
      self
    end

    def add x, y
      if @empty
        @minx = @maxx = x
        @miny = @maxy = y
      end
      @minx = [@minx, x].min
      @miny = [@miny, y].min
      @maxx = [@maxx, x].max
      @maxy = [@maxy, y].max
      @empty = false
      self
    end

    def add_geometry(geometry)
      rbbox = RGeo::Cartesian::BoundingBox.new geometry.factory
      rbbox.add geometry
      add rbbox.min_x, rbbox.min_y
      add rbbox.max_x, rbbox.max_y
      self
    end

    def minx
      @minx
    end

    def miny
      @miny
    end

    def maxx
      @maxx
    end

    def maxy
      @maxy
    end

    def centroid
      [ (@maxx + @minx)/2.0, (@maxy + @miny)/2.0 ]
    end

    def min
      [@minx, @miny]
    end

    def max
      [@maxx, @maxy]
    end

    def ratio
      (@maxx - @minx) / (@maxy - @miny)
    end

    def expand rate = @@epsilon
      _minx, _miny = [@minx - rate, @miny - rate]
      _maxx, _maxy = [@maxx + rate, @maxy + rate]
      reset
      add _minx, _miny
      add _maxx, _maxy
    end

    def include?(bbox)
      [@minx < bbox.minx, @miny < bbox.miny, @maxx > bbox.maxx, @maxy > bbox.maxy].all?
    end

    def constrict rate = @@epsilon
      expand -rate
    end

    def to_geometry
      factory = RGeo::Cartesian::Factory.new
      point_min, point_max = unless [@minx, @miny] == [@maxx, @maxy]
                               [factory.point(@minx, @miny), factory.point(@maxx, @maxy)]
                             else
                               [factory.point(@minx - @@epsilon, @miny - @@epsilon),
                                factory.point(@maxx + @@epsilon, @maxy + @@epsilon)]
                             end
      line_string = factory.line_string [point_min, point_max]
      line_string.envelope
    end

    def to_a
      [@minx, @miny, @maxx, @maxy]
    end

    def to_s
      to_a.join(', ')
    end

    def inspect
      "#<#{self.class} #{to_s}>"
    end

    def self.from_params(params)
      raw_bbox = JSON.load(params)
      bbox = self.new
      bbox.add raw_bbox['topLeft']['x'], raw_bbox['topLeft']['y']
      bbox.add raw_bbox['bottomRight']['x'], raw_bbox['bottomRight']['y']
      bbox
    end
  end
end
