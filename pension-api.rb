# Ruby 샘플 코드 #
require 'rubygems'
require 'rest-client'
require 'nokogiri'
require 'json'

module PensionAPI
  def PensionAPI::set_api_key()
    api_key = "7UmYLGjQHqLWPassQCa8xuuFiQ9ZWKGKMiQydPO7cBvLTDFL6ZGpdZZDMhxb9ZJw8CNzhf06dJSsjmply1XZMA=="
    return api_key
  end

  def PensionAPI::get_history_index(company_name, registration_number, recent = true)
    url = 'http://apis.data.go.kr/B552015/NpsBplcInfoInqireService/getBassInfoSearch'
    api_key = set_api_key()
    headers = {
        params: {
            'ServiceKey' => api_key,
            'wkpl_nm' => company_name,
            'bzowr_rgst_no' => parse_registration_number(registration_number),
            'pageNo' => '1'
        }
    }
    if recent
      headers[:params]["numOfRows"] = '1' # 최신 정보만
    else
      headers[:params]["numOfRows"] = '10'
    end

    begin
      response = RestClient.get(url, headers)
    rescue Exception
      puts("PensionAPI Error : 회사 식별변호를 가져올 수 없습니다.")
    end

    seq_list = []
    response = Nokogiri::XML(response)

    info = {
      'items' => []
    }
    # company = response.search('item').xpath('wkplNm/text()')[0]
    # puts(company)
    response.search('item').each do |item|
      company = item.at('wkplNm').text
      date = item.at('dataCrtYm').text
      seq = item.at('seq').text

      info['items'] << {
        company: company,
        date: date,
        seq: seq
      }
    end

    info["items"] = info["items"].sort_by{|index| index[:date]}.reverse

    return info
  end

  def PensionAPI::get_detailed_info(index)
    # url 가져온후
    url = "http://apis.data.go.kr/B552015/NpsBplcInfoInqireService/getDetailInfoSearch"
    api_key = set_api_key()
    headers = {
        params: {
            'ServiceKey' => api_key,
            'seq' => index[:seq]
        }
    }

    begin
      response = RestClient.get(url, headers)
    rescue Exception
      puts("PensionAPI Error : 회사 세부 정보를 가져올 수 없습니다.")
    end

    items = Nokogiri::XML(response)

    items.search('item').each do |item|
      employee_count = item.at('jnngpCnt').text.to_i
      paid_pension = item.at('crrmmNtcAmt').text.to_i
      pension_per_employee = (paid_pension/employee_count/ 2).to_i

    info = {
      company: index[:company],
      date: index[:date],
      # seq: index[:seq],
      employee_count: employee_count,
      paid_pension: paid_pension,
      pension_per_employee: pension_per_employee
    }

    return info
    end

  end

  # (회사 이름, 데이터 생성일, 직원수, 회사 총 연금, 직원 1인 평균 연금)
  def PensionAPI::get_company_info(company_name, registration_number, recent = true)
    index = get_history_index(company_name, registration_number, recent)
    # if index.include?('exception_msg')
    #   return {
    #     'statusCode' => 400,
    #     'exception_msg' => index[:exception_msg],
    #     'message' => '정보를 조회할 수 없습니다.'
    #   }
    # end

    result = []
    for info in index['items'] do
      detail_info = get_detailed_info(info)
      # if detail_info.include?('exception_msg')
      #   return {
      #     'statusCode' => 400,
      #     'exception_msg' => detail_info[:exception_msg],
      #     'message' => '정보를 조회할 수 없습니다.'
      #   }
      # end
      result.push(detail_info)
    end

    return {
      'statusCode' => 200,
      'body' => result.to_json
    }
  end

  # 최근 10개 정보 데이터 (생성일, 직원 수)
  def PensionAPI::get_company_count(company_name, registration_number, recent = true)
    company_info = get_company_info(company_name, registration_number, recent)
    json_info = JSON.parse(company_info["body"])
    list = []

    for info in json_info do
      date = info["date"]
      count = info["employee_count"]
      tmp = {
        date: date,
        count: count
      }
      list.push(tmp)
    end
    return {
      'statusCode' => 200,
      'body' => list.to_json
    }
  end
end

def parse_registration_number(number)
  return number.scan(/(\d{3})-(\d{2})-(\d{1})/).join("")
end