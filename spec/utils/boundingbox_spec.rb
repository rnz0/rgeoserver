require 'spec_helper'

describe RGeoServer::BoundingBox do
  subject { RGeoServer::BoundingBox.new }

  it 'should reset' do
    subject.to_a.should == [0.0, 0.0, 0.0, 0.0]
    subject.reset
    subject.to_a.should == [0.0, 0.0, 0.0, 0.0]
  end

  it 'should add point' do
    subject.add -1, 0
    subject.to_a.should == [-1, 0, -1, 0]
    subject.add -1, -1
    subject.to_a.should == [-1, -1, -1, 0]
    subject.add 1, -1
    subject.to_a.should == [-1, -1, 1, 0.0]
    subject.add 1, 1
    subject.to_a.should == [-1, -1, 1, 1]
  end

  it 'should generate geometry with different points' do
    subject.add -1, -1
    subject.add 1, 1
    polygon = subject.to_geometry
    polygon.geometry_type.should == RGeo::Feature::Polygon
    polygon.as_text.should == "POLYGON ((-1.0 -1.0, 1.0 -1.0, 1.0 1.0, -1.0 1.0, -1.0 -1.0))"
  end

  it 'should generate geometry with same points' do
    subject.add 1, 1
    polygon = subject.to_geometry
    polygon.geometry_type.should == RGeo::Feature::Point
    polygon.as_text.should == "POINT (1.0 1.0)"
  end
end
