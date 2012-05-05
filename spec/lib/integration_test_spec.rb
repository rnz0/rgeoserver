require 'spec_helper'

describe "Integration test against a GeoServer instance", :integration => true do
  CONFIG = RGeoServer::Config

  before(:all) do
    @catalog = RGeoServer.catalog
    @fixtures_dir = File.join(File.dirname(__FILE__), "/../fixtures/")
  end

  context "Namespaces" do 
    it "should instantiate a namespace resource" do
      obj = RGeoServer::Namespace.new @catalog, :name => 'test_ns'
      obj.new?.should == true
    end  

    it "should create a new namespace, update  and delete it right after" do
      obj = RGeoServer::Namespace.new @catalog, :name => 'test_ns', :uri => 'http://localhost'
      obj.new?.should == true
      obj.save
      obj.new?.should == false
      obj.uri = 'http://example.com'
      obj.save
      obj.uri.should_not == 'http://localhost'
      ws = RGeoServer::Workspace.new @catalog, :name => 'test_ns'
      ws.delete :recurse => true unless ws.new?
      obj = RGeoServer::Namespace.new @catalog, :name => 'test_ns', :uri => 'http://localhost'
      obj.new?.should == true
    end  

    it "should be in correspondence with workspaces" do
      pending "Make sure this also works on update and delete"
    end
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
      obj.delete(:recurse=>true) if !obj.new?
      obj.new?.should == true
      obj.profile.should == {}  
      obj.save
      obj.new?.should == false
      obj.enabled.should == 'true'
      obj.delete :recurse => true
    end

    it "should fail trying to delete unsaved (new) workspace" do
      obj = RGeoServer::Workspace.new @catalog, :name => 'test'
      obj.delete(:recurse=>true) if !obj.new?
      obj.delete.should raise_error
    end

    it "should fail trying to delete unexisting workspace names from catalog" do
      lambda{ ["asdfdg", "test3", "test5", "test6"].each{ |w| 
          @catalog.purge({:workspaces => w}, {:recurse  => true})
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
        @ws.data_stores do |ds| 
          ds.should be_kind_of(RGeoServer::DataStore)
          ["s1", "s2", "s3"].should include ds.name
        end
      end

    end
  end

  context "Layers" do 
    it "should instantiate a new layer" do
      lyr = RGeoServer::Layer.new @catalog, :name => 'layer_rgeoserver_test'
      lyr.new?.should == true
    end

    it "should not create a new layer directly" do
      lyr = RGeoServer::Layer.new @catalog, :name => 'layer_rgeoserver_test' 
      lyr.new?.should == true
      lyr.default_style = 'rain'
      lyr.alternate_styles = ['raster']
      lyr.enabled = 'true'
      lyr.resource = @catalog.get_coverage 'sf','sfdem', 'sfdem'
      expect{ lyr.save }.to raise_error
    end

    it "should list layers" do
      @catalog.get_layers.each { |l| 
        l.profile.should_not be_empty
      }
    end
  end

  context "LayerGroups" do
    it "should instantiate a new group layer" do
      lyrs = ['a','b','c'].collect{|l| RGeoServer::Layer.new @catalog, :name => l}
      stys = ['s1','s2','s3','s4'].collect{|s| RGeoServer::Style.new @catalog, :name => s}
      g = RGeoServer::LayerGroup.new @catalog, :name => 'test_group_layer'
      g.layers = lyrs
      g.styles = stys 
      g.new?.should == true
    end

    it "should create a new group layer from existing layers and styles and delete it right after" do
      g = RGeoServer::LayerGroup.new @catalog, :name => 'test_group_layer'
      g.layers = @catalog.get_layers[1,2]
      g.styles = @catalog.get_styles[1,2]
      g.new?.should == true
      g.save
      # Bounds metadata should come back aggregated from the server
      g.bounds['maxx'].should_not == ''
      g.delete
      g.new?.should == true
    end

  end

  context "Styles" do
    before :all do
      sld_dir = File.join(@fixtures_dir, 'styles')
      @test_sld = Nokogiri::XML(File.new(File.join(sld_dir, 'test_style.sld')))
      @pop_sld = Nokogiri::XML(File.new(File.join(sld_dir, 'poptest.sld')))
    end
 
    it "should instantiate a new style" do
      style = RGeoServer::Style.new @catalog, :name => 'style_rgeoserver_test'
      style.new?.should == true
    end

    it "should create new styles and delete them" do
      {'granules_test_style'=> @test_sld, 'poptest_test_style'=> @pop_sld}.each_pair do |name,sld_ng| 
        style = RGeoServer::Style.new @catalog, :name => name 
        style.sld_doc = sld_ng.to_xml
        style.save
        style.sld_doc.should be_equivalent_to(sld_ng)
        style.new?.should == false
        style.delete :purge => true
        style.new?.should == true
      end
    end
    
    it "should list layers that include a style" do
      @catalog.get_styles[1,1].each do |s|
        break
        s.profile.should_not be_empty
        s.layers do |l|
          lyrs = l.profile['alternate_styles'] + [l.profile['default_style']]
          lyrs.should include s.name unless lyrs.empty?
        end
      end
    end

  end

  context "Stores" do
    before :all do
      @ws = RGeoServer::Workspace.new @catalog, :name => 'test_workspace_for_stores'
      @ws.save
      @shapefile = File.join(@fixtures_dir, 'datasets/vector/granules.shp')
      @raster = File.join(@fixtures_dir, 'datasets/raster/test.tif')
    end
  
    after :all do
      @ws.delete :recurse => true
    end

    context "DataStores" do
      it "should list all available data stores" do
        @catalog.get_data_stores.each { |d|  
          d.profile.should_not be_empty
        }
      end

      it "should instantiate a datastore" do
        obj = RGeoServer::DataStore.new @catalog, :workspace => @ws, :name => 'test_shapefile'
        obj.new?.should == true
        obj.name.should == 'test_shapefile'
        obj.workspace.name.should == @ws.name 
      end

      it "should not create a datastore if workspace does not exit" do
        new_ws = RGeoServer::Workspace.new @catalog, :name => 'workspace_rgeoserver_test'
        obj = RGeoServer::DataStore.new @catalog, :workspace => new_ws, :name => 'test_random_store'
        obj.new? #.should raise_error 
      end

      it "should create a datastore under existing workspace, update and delete it right after" do
        ds = RGeoServer::DataStore.new @catalog, :workspace => @ws, :name => 'test', :connection_parameters => {"namespace"=>"http://test_workspace_for_stores", "url" => "file:#{@shapefile}"}
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

      it "should create a datastore under existing workspace and add a feature type that will also create a layer" do
        ds = RGeoServer::DataStore.new @catalog, :workspace => @ws, :name => 'test', :connection_parameters => {"namespace"=>"http://test_workspace_for_stores", "url" => "file:#{@shapefile}"}
        ds.new?.should == true
        ds.save
        ft = RGeoServer::FeatureType.new @catalog, :workspace => @ws, :data_store => ds, :name => 'granules'
        ft.save
        
      end
    end

    context "CoverageStores" do
      it "should list all available coverage stores" do
        @catalog.get_coverage_stores.each { |c|  
          c.profile.should_not be_empty
        }
      end
      it "should create a coverage store under existing workspace, update and delete it right after" do
        cs = RGeoServer::CoverageStore.new @catalog, :workspace => @ws, :name => 'test_coverage_store'
        cs.url = "file://#{@raster}"
        cs.description = 'description'
        cs.enabled = 'true'
        cs.data_type = 'GeoTIFF'
        cs.new?.should == true
        cs.save 
        cs.new?.should == false
        cs.description = 'new description'
        cs.description_changed?.should == true
        cs.save
        cs.description.should == 'new description'
        cs.new?.should == false
      end
      it "should create a coverage store under existing workspace and add a coverage to it. A layer must be created as a result of this operation" do
        cs = RGeoServer::CoverageStore.new @catalog, :workspace => @ws, :name => 'raster'
        cs.url = "file://#{@raster}"
        cs.description = 'description'
        cs.enabled = 'true'
        cs.data_type = 'GeoTIFF'
        cs.save
        c = RGeoServer::Coverage.new @catalog, :workspace => @ws, :coverage_store => cs, :name => 'raster'
        c.title = 'Test Raster Layer'
        #c.save
      end
    end
  
    context "Catalog operations" do
      it "should reload the catalog"  do
        @catalog.reload
      end
  
      it "should reset the catalog" do
        @catalog.reset
      end
  
    end
  end
end
