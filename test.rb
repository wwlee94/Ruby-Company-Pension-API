# Ruby 샘플 코드 #


require 'rubygems'
require 'rest_client'
require 'cgi'

url = 'http://apis.data.go.kr/B552015/NpsBplcInfoInqireService/getPdAcctoSttusInfoSearch'
headers = { :params => { CGI::escape('ServiceKey') => '서비스키',CGI::escape('seq') => '17735069',CGI::escape('data_crt_ym') => '201512' } }
response = RestClient::Request.execute :method => 'GET', :url => url , :headers => headers
puts response
