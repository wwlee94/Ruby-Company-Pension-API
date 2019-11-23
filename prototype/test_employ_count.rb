require './pension_api_class_version'
require 'json'

# 최근 10개 정보의 직원 수 리스트
count = PensionApi.get_company_count('당근마켓', '375-87-0', false)
puts(count)
