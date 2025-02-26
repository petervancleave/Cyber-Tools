require 'net/http'

def grab_http_banner(url)
  uri = URI(url)
  response = Net::HTTP.get_response(uri)
  
  puts "Server banner: #{response['server']}"
  puts "Status code: #{response.code}"
end

# example
grab_http_banner('http://example.com')
