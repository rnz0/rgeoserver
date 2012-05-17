# -*- encoding : utf-8 -*-

# RGeoServer Batch demo (batch_demo.rb)

#require 'rubygems'
require 'yaml'
require 'rgeoserver'

#=  Input data. 
# Assume we have a YAML file (layers.yaml) with records of the form:

# record_19:
#   filename: g3881015alpha.tif
#   title: Antietam 1867
#   layername: antietam_1867
#   size: 208 MB
#   projection: GCS_WGS_1984
#   format: GeoTIFF
#   description: Map shows the U.S. Civil War battle of Antietam.  It indicates fortifications,
#     roads, railroads, houses, names of residents, fences, drainage, vegetation, and
#     relief by hachures.
#   metadata: http://example.com/geonetwork/srv/en/fgdc.xml?id=1090 


# After parsing we save it in the $layers variable.
$layers = YAML::load(File.open(File.join(File.dirname(__FILE__), 'layers.yaml')))

# The records will look like this

# ["record_19", {"format"=>"GeoTIFF", "size"=>"208 MB", "title"=> "Antietam 1867", "metadata"=>"http://example.com/geonetwork/srv/en/fgdc.xml?id=1090", "projection"=>"GCS_WGS_1984", "filename"=>"g3881015alpha.tif", "description"=>"Map shows the U.S. Civil War battle of Antietam.  It indicates fortifications, roads, railroads, houses, names of residents, fences, drainage, vegetation, and relief by hachures.", "layername"=>"Antietam 1867"}]

# Connect to the GS catalog
$c = RGeoServer::Catalog.new :url=>"http://geoserver.example.com/geoserver/rest", :geowebcache_url => "http://geoserver.example.com/geoserver/gwc/rest", :password=>"admin", :user=>"admin" 

# Obtain a handle to the workspace. 
ws = RGeoServer::Workspace.new $c, :name => 'orbis'
ws.delete :recurse => true unless ws.new? # comment or uncomment to start from scratch
ws.save if ws.new?

# GWC configuration
SEED = false
SEED_OPTIONS = {
  :srs => {
    :number => 4326 
  },
  :zoomStart => 1,
  :zoomStop => 10,
  :format => 'image/png',
  :threadCount => 1
}

# Iterate over all records in YAML file and create stores in the catalog

$layers.each{ |id, val|   
  title = val['title']
  layername = val['layername']
  format = val['format']
  metadata = val['metadata']
  filename = val['filename']
  description = val['description'
  name = layername

  if format == 'GeoTIFF'
    begin 
      # Create of a coverage store
      cs = RGeoServer::CoverageStore.new $c, :workspace => ws, :name => name
      cs.url = "file:///geo_data/staging/#{filename}"
      cs.description = description 
      cs.enabled = 'true'
      cs.data_type = format
      cs.save
      # Now create the actual coverage
      cv = RGeoServer::Coverage.new $c, :workspace => ws, :coverage_store => cs, :name => name 
      cv.title = title 
      cv.save
      #cv.metadata_links = [{"type"=>"text/plain", "metadataType"=>"FGDC", "content"=> metadata}]
      #cv.save
      # Check if a layer has been created, extract some metadata
      lyr = RGeoServer::Layer.new $c, :name => name
      if !lyr.new? && SEED
        lyr.seed :issue, SEED_OPTIONS
      end
    rescue Exception => e
      puts e.inspect
    end

  elsif format == 'Shapefile'
    begin 
      # Create data stores for shapefiles
      cs = RGeoServer::DataStore.new $c, :workspace => ws, :name => name
      cs.connection_parameters = {
        "url" =>  "file:///geo_data/staging/#{filename}",
        "namespace" => "http://example.com"
      }
      cs.enabled = 'true'
      cs.save
      ft = RGeoServer::FeatureType.new $c, :workspace => ws, :data_store => cs, :name => name 
      ft.title = title 
      ft.abstract = description
      ft.save
    rescue Exception => e
      puts e.inspect
    end
  end
}
