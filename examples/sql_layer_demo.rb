# -*- encoding: utf-8 -*-

# RGeoServer Example for creating a layer with a database store
# Tested with GeoServer version 2.1.3 and PosgreSQL 9.1.1. with Postgis 2.0 

require 'rgeoserver'

$catalog = RGeoServer::Catalog.new :url => 'http://localhost:8080/geoserver/rest', :user => 'admin', :password => 'geoserver'

# 1. Register a POSTGIS database as data store in GeoServer
connection_parameters = {
  "Connection timeout"            => "20", 
  "port"                          => "5432",   
  "database"                      => "geodata", 
  "schema"                        => "public", 
  "user"                          => "geouser", 
  "passwd"                        => "geopass", 
  "dbtype"                        => "postgis", 
  "host"                          => "localhost", 
  "validate connections"          => "false", 
  "max connections"               => "10", 
  "namespace"                     => "rhine", 
  "Loose bbox"                    => "true", 
  "Expose primary keys"           => "true", 
  "Max open prepared statements"  => "50", 
  "fetch size"                    => "1000", 
  "preparedStatements"            => "false", 
  "Estimated extends"             => "true", 
  "min connections"               => "1"
}


ds = RGeoServer::DataStore.new $catalog, :name => 'sql_example', :workspace => nil
ds.connection_parameters = connection_parameters
ds.enabled = 'true'

if ds.new?
  puts "Creating datastore #{ds.name} in #{$catalog}/workspaces/default"
  ds.save
end

# 2. We create a feature type to point to an actual table in the database.
# Make sure the user has privileges to access the table otherwise you will get a remote 
# java.io.IOException: Error looking up primary key
# ...
# Caused by: org.postgresql.util.PSQLException: ERROR: permission denied for relation gnis_populated_places
# ...
# Caused by: org.postgresql.util.PSQLException: ERROR: permission denied for relation geometry_columns

ft = RGeoServer::FeatureType.new $catalog, :name => 'gnis_populated_places', :worskpace => nil, :data_store => ds
ft.save if ft.new?


# 3. Now we verify that a layer was created

lyr = RGeoServer::Layer.new $catalog, :name => 'gnis_populated_places'

# We test the layer has the right profile. 
# This is not too honest since the profile was looked up first. 
expected_profile = {
  "name"  =>  "gnis_populated_places", 
  "path"  =>  "", 
  "default_style" =>  "point", 
  "alternate_styles"  =>  [], 
  "type"  =>  "VECTOR", 
  "enabled" =>  "true", 
  "queryable" =>  "", 
  "attribution" =>  {
    "title" => "", 
    "logo_width"  =>  "0", 
    "logo_height" =>  "0"
  }, 
  "resource"  =>  {
    "type"  =>  "featureType", 
    "name"  =>  "gnis_populated_places", 
    "store" =>  "sql_example", 
    "workspace" =>  "it.geosolutions"
  }, 
  "metadata"  =>  {
    "GWC.metaTilingX" =>  "4", 
    "GWC.autoCacheStyles" =>  "true", 
    "GWC.metaTilingY" =>  "4", 
    "GWC.gutter"  =>  "0", 
    "GWC.enabled" =>  "true", 
    "GWC.gridSets"=>  "EPSG:4326,EPSG:900913",
    "GWC.cacheFormats"  =>  "image/png,image/jpeg"
  }
}
raise "Unexpected profile for layer" if lyr.profile != expected_profile
 
