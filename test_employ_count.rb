require './pension-api'
require 'json'

# 최근 10개 정보의 직원 수 리스트
count = PensionAPI::get_company_count('당근마켓', '375-87-00088', true)
puts(count)
