module Geokit
  module Geocoders
    # Bing geocoder implementation.  Requires the Geokit::Geocoders::BING variable to
    # contain a Bing Maps API key.  Conforms to the interface set by the Geocoder class.
    class BingGeocoder < Geocoder

      private

      # Template method which does the geocode lookup.
      def self.do_geocode(address, options = {})
        address_str = address.is_a?(GeoLoc) ? address.to_geocodeable_s : address
        url="http://dev.virtualearth.net/REST/v1/Locations/#{URI.escape(address_str)}?key=#{Geokit::Geocoders::bing}&o=xml"
        res = self.call_geocoder_service(url)
        return GeoLoc.new if !res.is_a?(Net::HTTPSuccess)
        xml = res.body
        logger.debug "Bing geocoding. Address: #{address}. Result: #{xml}"
        return self.xml2GeoLoc(xml, address)
      end

      def self.xml2GeoLoc(xml, address="")
        doc=REXML::Document.new(xml)
        if doc.elements['//Response/StatusCode'] && doc.elements['//Response/StatusCode'].text == '200'
          geoloc = nil
          # Bing can return multiple results as //Location elements.
          # iterate through each and extract each location as a geoloc
          doc.each_element('//Location') do |l|
            extracted_geoloc = extract_location(l)
            geoloc.nil? ? geoloc = extracted_geoloc : geoloc.all.push(extracted_geoloc)
          end
          return geoloc
        else
          logger.debug "Bing was unable to geocode address: "+address
          return GeoLoc.new
        end

      rescue
        logger.error "Caught an error during Bing geocoding call: "+$!
        return GeoLoc.new
      end

      # extracts a single geoloc from a //Location element in the bing results xml
      def self.extract_location(doc)
        res                 = GeoLoc.new
        res.provider        = 'bing'
        res.lat             = doc.elements['.//Latitude'].text         if doc.elements['.//Latitude']
        res.lng             = doc.elements['.//Longitude'].text        if doc.elements['.//Longitude']
        res.city            = doc.elements['.//Locality'].text         if doc.elements['.//Locality']
        res.state           = doc.elements['.//AdminDistrict'].text    if doc.elements['.//AdminDistrict']
        res.province        = doc.elements['.//AdminDistrict2'].text   if doc.elements['.//AdminDistrict2']
        res.full_address    = doc.elements['.//FormattedAddress'].text if doc.elements['.//FormattedAddress']
        res.zip             = doc.elements['.//PostalCode'].text       if doc.elements['.//PostalCode']
        res.street_address  = doc.elements['.//AddressLine'].text      if doc.elements['.//AddressLine']
        res.country         = doc.elements['.//CountryRegion'].text    if doc.elements['.//CountryRegion']
        if doc.elements['.//Confidence']
          res.accuracy      = case doc.elements['.//Confidence'].text
          when 'High'    : 8
          when 'Medium'  : 5
          when 'Low'     : 2
          else             0
          end
        end
        if doc.elements['.//EntityType']
          res.precision     = case doc.elements['.//EntityType'].text
          when 'Sovereign'      : 'country'
          when 'AdminDivision1' : 'state'
          when 'AdminDivision2' : 'state'
          when 'PopulatedPlace' : 'city'
          when 'Postcode1'      : 'zip'
          when 'Postcode2'      : 'zip'
          when 'RoadBlock'      : 'street'
          when 'Address'        : 'address'
          else                    'unkown'
          end
        end
        if suggested_bounds = doc.elements['.//BoundingBox']
          res.suggested_bounds = Bounds.normalize(
            [suggested_bounds.elements['.//SouthLatitude'].text, suggested_bounds.elements['.//WestLongitude'].text],
            [suggested_bounds.elements['.//NorthLatitude'].text, suggested_bounds.elements['.//EastLongitude'].text])
        end
        res.success         = true
        return res
      end

    end
  end
end