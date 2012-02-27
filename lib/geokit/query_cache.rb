require 'md5'

module Geokit

  # A Simple Query Caching mechanism for "forward-caching" HTTP queries.
  # 
  # Adapted from the Yahoo Developer Network's Guide:
  # 
  # Cache Yahoo! Web Service Calls using Ruby
  # 
  # http://developer.yahoo.com/ruby/ruby-cache.html
  # 
  module QueryCache

    class DiskFetcher

      # Create a new DiskFetcher object.  Default +cache_dir+ is /tmp.
      # 
      def initialize(cache_dir='/tmp')
        @cache_dir = cache_dir
      end

      # Caches the requested +url+ using the Net::HTTP library. Uses the 
      # passed in block to perform the necessary Net::HTTP logic.
      # 
      # Marshals the entire return object to disk to allow drop-in 
      # replacement for Net::HTTP request calls.
      # 
      def do_cache_request(url, max_age=0, &block)
        file = MD5.hexdigest(url)
        file_path = File.join(@cache_dir, file)
        file_contents = ""
        # Check if the file -- a MD5 hexdigest of the URL -- exists
        # in the dir. If it does and the data is fresh, read
        # data from the file and return
        if File.exists? file_path
          if Time.now - File.mtime(file_path) < max_age
            data = File.new(file_path).read
            return Marshal.load(data)
          end
        end
        # If the file does not exist (or if the data is not fresh), 
        # make an HTTP request and save it to a file
        File.open(file_path, "w") do |data|
          file_contents = block.call() if block_given?
          data << Marshal.dump(file_contents)
        end
        return file_contents
      end
      
    end
    
  end
  
end
