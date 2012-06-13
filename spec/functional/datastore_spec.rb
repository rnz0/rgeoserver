require 'spec_helper'

describe RGeoServer::DataStore do
  let(:old_test_ds_xml){ 
     File.read(File.expand_path('../fixtures/resources/datastore/old.xml', File.dirname(__FILE__))) 
  }
  let(:old_test_ds_featuretypes_xml){
     File.read(File.expand_path('../fixtures/resources/datastore/old_featuretypes.xml', File.dirname(__FILE__))) 
  }
  let(:catalog) { 
    c = double('Catalog') 
    # Stub profile responses
    # For a new datastore
    c.stub(:search).with({"workspaces/test_ws/datastores"=>"new_test_ds"}).and_raise(RestClient::ResourceNotFound)
    # For a supposed existing datastore
    c.stub(:search).with({"workspaces/test_ws/datastores"=>"old_test_ds"}).and_return(old_test_ds_xml)
    # Fake featuretypes response for a new datastore
    c.stub(:do_url).with("https://geodata.example.com/geoserver/rest/workspaces/test_ws/datastores/sites_shape/featuretypes.xml").and_raise(
      RestClient::ResourceNotFound
    )
    # Fake featuretypes response for an existing (old) datastore
    c.stub(:do_url).with("https://geodata.example.com/geoserver/rest/workspaces/test_ws/datastores/sites_shape/featuretypes.xml").and_return(
      old_test_ds_featuretypes_xml
    )
    c
  }
  let(:workspace) { 
    w = double('Workspace')
    w.stub(:instance_of?).with(String).and_return(false)
    w.stub(:instance_of?).with(RGeoServer::Workspace).and_return(true)
    w.stub(:name).and_return('test_ws')
    w
  }

  describe "#new" do
    it 'should not allow empty parameters' do
      expect{ RGeoServer::DataStore.new }.to raise_error ArgumentError
    end   
    it 'should not allow null name' do 
      expect { RGeoServer::DataStore.new catalog, :workspace => workspace }.to raise_error
    end

    it 'should not allow empty workspace' do
      expect { RGeoServer::DataStore.new catalog, :name => 'test_ds' }.to raise_error
    end 

    it 'should allow non null catalog, workspace and name' do 
      ds = RGeoServer::DataStore.new catalog, :workspace => workspace, :name => 'test_ds'
    end

  end

  describe "#connection_parameters" do
    it 'should not override connection_parameters if on a existing datastore with non empty connection parameters' do
      ds = RGeoServer::DataStore.new catalog, :workspace => workspace, :name => 'old_test_ds'
      ds.connection_parameters.should == {
        "memory mapped buffer"=>"false", 
        "create spatial index"=>"true", 
        "charset"=>"ISO-8859-1", 
        "filetype"=>"shapefile",
        "cache and reuse memory maps"=>"true", 
        "url"=>"file:data/shapefiles/o_sites.shp", 
        "namespace"=>"http://www.openplans.org/spearfish"
      }
    end 

    it 'should have empty connection_parameters on new datastores' do 
      ds = RGeoServer::DataStore.new catalog, :workspace => workspace, :name => 'new_test_ds'
      ds.connection_parameters.should be_empty 
    end

  end

  describe "#featuretypes" do
    it 'should list feature types in datastore' do
      ds = RGeoServer::DataStore.new catalog, :workspace => workspace, :name => 'old_test_ds'
      # there is only one feature type in fixture response old_featuretypes.xml 
      ds.featuretypes.size.should == 1
      ft = ds.featuretypes.first
      ft.should be_an_instance_of(RGeoServer::FeatureType)
      ft.name.should == 'o_sitesnew'
    end

    it 'should return an empty array of datastore is new or has no feature type resources' do
      ds = RGeoServer::DataStore.new catalog, :workspace => workspace, :name => 'new_test_ds'
      ds.featuretypes.should be_empty
    end
  end

  describe "#profile_xml_to_hash" do
    it 'should parse correctly profile_xml response for existing datastores' do
      # this is called implicitely in previous tests  
    end
  end
end

