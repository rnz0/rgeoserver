require 'confstruct/configuration'

module RGeoServer
  Config = Confstruct::Configuration.new(YAML.load(File.read(File.expand_path('../../../config/config_defaults.yml', __FILE__))))
end


