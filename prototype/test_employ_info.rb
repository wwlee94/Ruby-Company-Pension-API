require './pension_api_class_prototype'
require 'json'
# 기타 정보 포함
count = PensionApi.get_company_info('당근마켓', '375-87-00088', false)
puts(count)
