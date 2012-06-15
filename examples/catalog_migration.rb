# -*- encoding : utf-8 -*-

# RGeoServer Catalog Migration example (catalog_migration.rb)

# require rubygems
require 'rgeoserver'

# The source catalog is a GeoServer instance version 2.1.0
$source_gs = RGeoServer::Catalog.new :url=> 'https://oldgeodata.example.com/geoserver/rest', :user=>'renzo', :password=>'changeme'

# The target catalog is a GeoServer instance version 2.1.3
$target_gs = RGeoServer::Catalog.new :url=> 'http://newgeodata.example.com/geoserver/rest', :user=> 'admin', :password => 'geoserver'

# We don't migrate all workspaces except the following:
$workspaces_to_migrate = [
  'orbis',
  'barrington',
  'authorial_london',
  'rhine',
  'Operas'
]

# Cleanup target. Comment out if this runs in succesive trials
$target_gs.get_workspaces.each do |w| w.delete :recurse=> true end

# Migrate styles
$source_gs.get_styles.each do |s_s|
  s_t = RGeoServer::Style.new $target_gs, :name => s_s.name
  s_t.sld_doc = s_s.sld_doc
  begin
    s_t.save
  rescue Exception => e
    puts "Error creating style #{s_s.name}:\n #{e}"
  end
end

# Migrate workspaces
$source_gs.get_workspaces.each do |ws_s| 
  next unless $workspaces_to_migrate.include? ws_s.name
  ws_t = RGeoServer::Workspace.new $target_gs, :name => ws_s.name
  if ws_t.new?
    puts "Creating workspace #{ws_s.name} in #{$target_gs}"
    ws_t.save
    # Synchronize namespaces
    ns_s = RGeoServer::Namespace.new $source_gs, :name => ws_t.name
    ns_t = RGeoServer::Namespace.new $target_gs, :name => ns_s.name, :uri => ns_s.uri
    ns_t.save
  end

  # Migrate data stores per workspace
  ws_s.data_stores.each do |ds_s| 
    ds_t = RGeoServer::DataStore.new $target_gs, :name => ds_s.name, :workspace => ws_s
    puts "Creating datastore #{ds_s.name} in #{$target_gs}/workspaces/#{ws_s.name}"
    ds_t.connection_parameters = ds_s.connection_parameters
    ds_t.enabled = ds_s.enabled
    begin
      ds_t.save
    rescue Exception => e
      puts "Error creating data store #{ds_s.name}, workspace #{ws_s.name}:\n #{e}"
    end
    # Migrate feature types
    ds_s.featuretypes.each do |ft_s|
      ft_t = RGeoServer::FeatureType.new $target_gs, :name => ft_s.name, :workspace => ws_s, :data_store => ds_t
      begin
        ft_t.save
      rescue Exception => e
        puts "Error creating feature type #{ft_s.name}, workspace #{ws_s.name}, datastore #{ds_t.name}:\n #{e}"
      end
    end
  end
 
  # Coverage stores
  ws_s.coverage_stores.each do |cs_s|
    cs_t = RGeoServer::CoverageStore.new $target_gs, :name => cs_s.name, :workspace => ws_s
    cs_t.description = cs_s.description
    cs_t.enabled = cs_s.enabled
    cs_t.data_type = cs_s.data_type
    cs_t.url = cs_s.url
    begin
      cs_t.save
      puts "Coverage store #{cs_s.name}, workspace #{ws_s.name} was successfully created"
    rescue Exception => e
      puts "Error creating coverage store #{cs_s.name}, workspace #{ws_s.name}:\n #{e}"
    end
    # Coverages 
    cs_s.coverages.each do |c_s| 
      c_t = RGeoServer::Coverage.new $target_gs, :name => c_s.name, :workspace => ws_s, :coverage_store => cs_t
      c_t.title = c_s.title
      begin 
        c_t.save
        puts "Coverage layer #{c_s.name}, workspace #{ws_s.name} was successfully created"
      rescue Exception => e 
        puts "Error creating coverage layer #{c_s.name}, workspace #{ws_s.name}:\n #{e}, coveragestore #{cs_t.name}"
      end
    end
  end

end
