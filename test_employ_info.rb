require './pension-api'
require 'json'
# 기타 정보 포함
count = PensionAPI::get_company_info('당근마켓', '375-87-00088', false)
puts(count)
