
module RGeoServer
  module GeoServerUrlHelpers
    API_DOCUMENTATION = "http://docs.geoserver.org/latest/en/user/restconfig/rest-config-api.html"
  
    def url_for base, options = nil
      return base unless options.is_a? Hash
      format = options.delete(:format) || 'xml'
      new_base = base.map{ |key,value|  value.nil?? key.to_s : [key.to_s, CGI::escape(value.to_s)].join("/")  }.join("/") 
      new_base = new_base.gsub(/\/$/,'')
      new_base += ".#{format}"
      "#{new_base}" + (("?#{options.map { |key, value|  "#{CGI::escape(key.to_s)}=#{CGI::escape(value.to_s)}"}.join("&")  }" if options and not options.empty?) || '')

    end

  end
end
