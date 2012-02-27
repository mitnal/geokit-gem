require File.join(File.dirname(__FILE__), 'test_base_geocoder')

Geokit::Geocoders::query_cache         = true
Geokit::Geocoders::query_cache_max_age = 86400 # 1 day

class QueryCacheTest < BaseGeocoderTest #:nodoc: all
  
  TEST_API_RESULT=<<-EOF.strip
  <?xml version="1.0" encoding="UTF-8"?><test>result</test>
  EOF
  
  def setup
    super
    @test_tmp_dir = File.join(File.dirname(__FILE__), 'tmp')
    FileUtils.mkdir_p @test_tmp_dir
  end
  
  def teardown
    FileUtils.remove_dir @test_tmp_dir
  end
  
  def test_query_cache
    test_query_cache = Geokit::QueryCache::DiskFetcher.new(@test_tmp_dir)
    cached_result = test_query_cache.do_cache_request("http://www.anything.com", 86400 ) { TEST_API_RESULT }
    assert_equal cached_result, TEST_API_RESULT
  end
  
  def test_query_cache_returns_cached_content
    test_query_cache = Geokit::QueryCache::DiskFetcher.new(@test_tmp_dir)
    cached_result = test_query_cache.do_cache_request("http://www.anything.com", 86400 ) { TEST_API_RESULT }
    same_cached_result = test_query_cache.do_cache_request("http://www.anything.com", 86400 ) { "different result" }
    # should return the cached result, even when given a different "result"
    assert_equal same_cached_result, TEST_API_RESULT
  end
  
  def test_successful_call_query_cache_web_service
    url = "http://www.anything.com"
    Geokit::Geocoders::Geocoder.query_cache.expects(:do_cache_request).with(url, 86400).returns("SUCCESS")
    assert_equal "SUCCESS", Geokit::Geocoders::Geocoder.call_geocoder_service(url)
  end
  
end
