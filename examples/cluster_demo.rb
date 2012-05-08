# -*- encoding : utf-8 -*-

#require 'rubygems'
require 'rgeoserver'

layers = {
  'south_america_1787' => {
    'url' => 'file:///geo_data/rumsey/g0411047.tif',
    'description' => "Map of South America by D'Anville",
    'type' => 'GeoTIFF'
   },
  'city_of_san_francisco_1859' => {
    'url' => 'file:///geo_data/rumsey/g1030000alpha.tif',
    'description' => 'Map of San Francisco by the U.S. Coast Survey, with detail of the unsettled lands',
    'type' => 'GeoTIFF'
  }
}

(1..7).each do |cat_id| 
  cat = RGeoServer::Catalog.new :user=>'admin', :url => "http://geoserver-app#{cat_id}/rest", :password => "osgeo!"
  ws = cat.get_workspace('cite')
  RGeoServer::ResourceInfo.list(RGeoServer::CoverageStore, cat, layers.keys, :workspace => ws) do |cs|
    cs.description = layers[cs.name]['description']  
    cs.url = layers[cs.name]['url']  
    cs.data_type = layers[cs.name]['type']
    cs.enabled = 'true'
    cs.save
  end

end
