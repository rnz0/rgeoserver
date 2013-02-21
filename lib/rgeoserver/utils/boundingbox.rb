require 'rgeo'

module RGeoServer
  class BoundingBox
    attr_accessor :minx, :miny, :maxx, :maxy

    def initialize
      reset
    end

    def reset
      @minx = @miny = @maxx = @maxy = 0.0
      @empty = true
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
    end

    def to_geometry
      factory = RGeo::Cartesian::Factory.new
      point_min = factory.point @minx, @miny
      point_max = factory.point @maxx, @maxy
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
  end
end
