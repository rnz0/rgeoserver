require 'spec_helper'

describe RGeoServer::ShapefileInfo do
  let :fixtures_dir do
    File.expand_path File.join(File.dirname(__FILE__), "/../fixtures/")
  end

  let :shapefile_path do
    File.expand_path File.join(fixtures_dir, 'datasets/vector/granules.shp')
  end

  subject { RGeoServer::ShapefileInfo.new shapefile_path }

  it 'should return bounds' do
    bbox = subject.bounds
    bbox.to_a.should == [-123.0, 40.0, -122.0, 41.0]
  end

  it 'should return srid' do
    subject.srid.should == 0
  end
end
