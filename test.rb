# Ruby 샘플 코드 #
require 'rest-client'
require 'cgi'

url = 'http://apis.data.go.kr/B552015/NpsBplcInfoInqireService/getPdAcctoSttusInfoSearch'
headers = { :params => { CGI::escape('ServiceKey') => 'XaMtCJTJtlmQEGswOTfoO7XVM9uD7umqE05HBQhkAKPW1uAMeLeNU3UPnBrw6LRuLwsvXPLmxBO%2FT7T8rXoj%2Fw%3D%3D',
  CGI::escape('seq') => '17735069',CGI::escape('data_crt_ym') => '201512' } }
response = RestClient::Request.execute :method => 'GET', :url => url , :headers => headers
puts response
