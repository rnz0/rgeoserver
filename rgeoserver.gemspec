require File.join(File.dirname(__FILE__), "lib/rgeoserver/version")
Gem::Specification.new do |s|
  s.name = "rgeoserver"
  s.version = RGeoServer::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Renzo Sanchez-Silva"]
  s.email = ["renzo.sanchez.silva@gmail.com"]
  s.summary = %q{GeoServer REST API ruby library }
  s.description = %q{GeoServer REST API Ruby library : Requires GeoServer 2.1.3+}
  s.homepage = "http://github.com/rnz0/rgeoserver"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rest-client"
  s.add_dependency "nokogiri"
  s.add_dependency "mime-types"
  s.add_dependency "activesupport"
  s.add_dependency "activemodel"
  s.add_dependency "confstruct"

  s.add_development_dependency("rake")
  s.add_development_dependency("shoulda")
  s.add_development_dependency("bundler", ">= 1.0.14")
  s.add_development_dependency("rspec")
  s.add_development_dependency("yard")
  s.add_development_dependency("jettywrapper")
end

