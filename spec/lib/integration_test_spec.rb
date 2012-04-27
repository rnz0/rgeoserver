require 'spec_helper'

describe "Integration test against a GeoServer instance", :integration => true do
  CONFIG = RGeoServer::Config

  before(:all) do
    @catalog = RGeoServer.catalog
  end

  context "Workspaces" do 
    it "should list workspaces" do
      @catalog.get_workspaces.each{ |obj|
        obj.profile.should_not be_nil
      } 
    end

    it "should return workspace from catalog" do
      obj = @catalog.get_workspace 'topp'
      obj.profile.should_not be_empty 
    end

    it "should instantiate an existing worskpace object" do
      obj = RGeoServer::Workspace.new @catalog, :name => 'topp'
      obj.new?.should == false
      obj.profile.should_not == {}
    end

    it "should save new items" do
      obj = RGeoServer::Workspace.new @catalog, :name => 'test_ws'
      obj.delete(:purge=>true) if !obj.new?
      obj.new?.should == true
      obj.profile.should == {}  
      obj.save
      obj.new?.should == false
      obj.enabled.should == true
      obj.delete :purge => true
    end

    it "should fail trying to delete unsaved (new) workspace" do
      obj = RGeoServer::Workspace.new @catalog, :name => 'test'
      obj.delete(:purge=>true) if !obj.new?
      obj.delete.should raise_error
    end

    it "should fail trying to delete unexisting workspace names from catalog" do
      lambda{ ["asdfdg", "test3", "test5", "test6"].each{ |w| 
          @catalog.purge({:workspaces => w}, {:purge  => true})
        }
      }.should raise_error
    end

    context "Datastores of a Workspace" do
      before :all do
        @ws = RGeoServer::Workspace.new @catalog, :name => 'test_workspace_with_stores'
        @ws.save 
        ["s1", "s2","s3"].each{ |s|
          ds = RGeoServer::DataStore.new @catalog, :workspace => @ws, :name => s
          ds.save 
        }
      end

      after :all do
        @ws.delete :recurse => true
      end

      it "should list datastore objects that belong to it" do

        @ws.data_stores.each{ |ds| 
          ds.should be_kind_of(RGeoServer::DataStore)
          ["s1", "s2", "s3"].should include ds.name
        }
      end

    end
  end

  context "Stores" do
    before :all do
      @ws = RGeoServer::Workspace.new @catalog, :name => 'test_workspace_for_stores'
      @ws.save
    end
  
    after :all do
      @ws.delete :purge => true
    end

    context "DataStores" do
      it "should instantiate a datastore" do
        obj = RGeoServer::DataStore.new @catalog, :workspace => @ws, :name => 'test_shapefile'
        obj.new?.should == true
        obj.name.should == 'test_shapefile'
        obj.workspace.name.should == @ws.name 
      end

      it "should not create a datastore if workspace does not exit" do
        new_ws = RGeoServer::Workspace.new @catalog, :name => SecureRandom.hex(5)
        obj = RGeoServer::DataStore.new @catalog, :workspace => new_ws, :name => 'test_random_store'
        obj.new?.should raise_error 
      end

      it "should create a datastore under existing workspace and update it right after" do
        ds = RGeoServer::DataStore.new @catalog, :workspace => @ws, :name => 'test', :connection_parameters => {"namespace"=>"http://test_workspace_for_stores", "url" => "file://tmp/geo.tif"}
        ds.new?.should == true
        ds.save
        ds.new?.should == false
        ds.delete
        ds.new?.should == true

        # Add new information
        new_connection_parameters = {"namespace"=>"http://localhost/test_with_stores", "url" => 'file:data/taz_shapes'}
        ds.connection_parameters = new_connection_parameters 
        ds.changed?.should == true
        ds.save
        ds.profile['connectionParameters'].should == new_connection_parameters
        ds.delete
      end
    end
  end
end
