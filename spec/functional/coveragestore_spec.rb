require 'spec_helper'

describe RGeoServer::CoverageStore do
  let(:old_cs_xml){
    File.read(File.expand_path('../fixtures/resources/coveragestore/old.xml', File.dirname(__FILE__))) 
  }
  let(:old_cs_coverages_xml){
    File.read(File.expand_path('../fixtures/resources/coveragestore/old_coverages.xml', File.dirname(__FILE__))) 
  } 
  let(:catalog) { 
    c = double('Catalog') 
    # Stub profile responses
    # For a new coveragestore
    c.stub(:search).with({"workspaces/authorial_london/coveragestores"=>"new_test_cs"}).and_raise(RestClient::ResourceNotFound)
    # For a supposed existing datastore
    c.stub(:search).with({"workspaces/authorial_london/coveragestores"=>"old_cs"}).and_return(old_cs_xml)
    # Fake coverages response for a new datastore
    c.stub(:do_url).with("http://geodata.example.com/geoserver/rest/workspaces/authorial_london/coveragestores/sites_shape/coverages.xml").and_raise(
      RestClient::ResourceNotFound
    )
    # Fake coverages response for an existing (old) datastore
    c.stub(:do_url).with("http://geodata.example.com/geoserver/rest/workspaces/authorial_london/coveragestores/london_1843/coverages.xml").and_return(
      old_cs_coverages_xml
    )
    c
  }
  let(:workspace) { 
    w = double('Workspace')
    w.stub(:instance_of?).with(String).and_return(false)
    w.stub(:instance_of?).with(RGeoServer::Workspace).and_return(true)
    w.stub(:name).and_return('authorial_london')
    w
  }

  describe "#new" do
    it 'should not allow empty parameters' do
      expect{ RGeoServer::CoverageStore.new }.to raise_error ArgumentError
    end   
    it 'should not allow null name' do 
      expect { RGeoServer::CoverageStore.new catalog, :workspace => workspace }.to raise_error
    end

    it 'should not allow empty workspace' do
      expect { RGeoServer::CoverageStore.new catalog, :name => 'test_cs' }.to raise_error
    end 

    it 'should allow non null catalog, workspace and name' do 
      cs = RGeoServer::CoverageStore.new catalog, :workspace => workspace, :name => 'test_cs'
    end

  end

  describe "#coverages" do
    it 'should list coverages in coveragestore' do
      cs = RGeoServer::CoverageStore.new catalog, :workspace => workspace, :name => 'old_cs'
      cs.coverages.size.should == 2
      c = cs.coverages.first
      c.should be_an_instance_of(RGeoServer::Coverage)
      ['london_1843', 'London_17C'].should include c.name
    end

    it 'should return an empty array of coveragestores if new or has no feature type resources' do
      ds = RGeoServer::CoverageStore.new catalog, :workspace => workspace, :name => 'new_test_cs'
      ds.coverages.should be_empty
    end
  end

end 
