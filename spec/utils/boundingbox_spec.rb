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

  it 'should expand with default' do
    subject.add 1, 1
    subject.expand
    subject.to_a.should ==
      [1 - RGeoServer::BoundingBox.epsilon, 1 - RGeoServer::BoundingBox.epsilon,
       1 + RGeoServer::BoundingBox.epsilon, 1 + RGeoServer::BoundingBox.epsilon]
  end

  it 'should constrict with default' do
    subject.add 1, 1
    subject.constrict
    subject.to_a.should ==
      [1 - RGeoServer::BoundingBox.epsilon, 1 - RGeoServer::BoundingBox.epsilon,
       1 + RGeoServer::BoundingBox.epsilon, 1 + RGeoServer::BoundingBox.epsilon]
  end

  it 'should expand with rate' do
    rate = 5
    subject.add 1, 1
    subject.expand rate
    subject.to_a.should == [1 - rate, 1 - rate, 1 + rate, 1 + rate]
  end

  it 'should constrict with rate' do
    rate = 5
    subject.add 1, 1
    subject.constrict rate
    subject.to_a.should == [1 - rate, 1 - rate, 1 + rate, 1 + rate]
  end

  it 'should constrict having non-zero area' do
    rate = 0.2
    subject.add -1, -1
    subject.add 1, 1
    subject.constrict rate
    subject.to_a.should == [-1 + rate, -1 + rate, 1 - rate, 1 - rate]
  end

  it 'should generate geometry with different points' do
    subject.add -1, -1
    subject.add 1, 1
    polygon = subject.to_geometry
    polygon.geometry_type.should == RGeo::Feature::Polygon
    polygon.as_text.should ==
      "POLYGON ((-1.0 -1.0, 1.0 -1.0, 1.0 1.0, -1.0 1.0, -1.0 -1.0))"
  end

  it 'should generate geometry with same points' do
    subject.add 1, 1
    polygon = subject.to_geometry
    polygon.geometry_type.should == RGeo::Feature::Polygon
    polygon.as_text.should ==
      "POLYGON ((0.9999 0.9999, 1.0001 0.9999, 1.0001 1.0001, 0.9999 1.0001, 0.9999 0.9999))"
  end
end
