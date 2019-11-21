require 'rubygems'
require 'rest-client'
require 'nokogiri'
require 'json'

class PensionApi
  BASE_API_URL = 'http://apis.data.go.kr/B552015/NpsBplcInfoInqireService'.freeze
  API_KEY = '7UmYLGjQHqLWPassQCa8xuuFiQ9ZWKGKMiQydPO7cBvLTDFL6ZGpdZZDMhxb9ZJw8CNzhf06dJSsjmply1XZMA=='.freeze
  MAXIMUM_HISTORY_INDEX = 100

  class << self
    def get_history_index(company_name, registration_number, recent = true)
      url = "#{BASE_API_URL}/getBassInfoSearch"
      headers = {
        params: {
          ServiceKey: API_KEY,
          wkpl_nm: company_name,
          bzowr_rgst_no: parse_registration_number(registration_number),
          pageNo: '1',
          numOfRows: MAXIMUM_HISTORY_INDEX.to_s
        }
      }

      begin
        response = RestClient.get(url, headers)
      rescue StandardError
        puts('PensionAPI Error : 회사 식별변호를 가져올 수 없습니다.')
        return
      end

      response = Nokogiri::XML(response)

      info = {
        items: []
      }
      response.search('item').each do |item|
        company = item.at('wkplNm').text
        date = item.at('dataCrtYm').text
        seq = item.at('seq').text

        info[:items] << {
          company: company,
          date: date,
          seq: seq
        }
      end

      info[:items] = info[:items].sort_by { |index| index[:date] }.reverse

      if recent
        current = info[:items].first

        info = {
          items: []
        }
        info[:items] << current
      end

      info
    end

    def get_detailed_info(index)
      url = "#{BASE_API_URL}/getDetailInfoSearch"
      headers = {
        params: {
          ServiceKey: API_KEY,
          seq: index[:seq]
        }
      }

      begin
        response = RestClient.get(url, headers)
      rescue StandardError
        puts('PensionAPI Error : 회사 세부 정보를 가져올 수 없습니다.')
        return
      end

      item = Nokogiri::XML(response).search('item')[0]

      {
        company: index[:company],
        date: index[:date],
        employee_count: item.at('jnngpCnt').text.to_i,
        paid_pension: item.at('crrmmNtcAmt').text.to_i
      }
    end

    # (회사 이름, 데이터 생성일, 직원수, 회사 총 연금, 직원 1인 평균 연금)
    def get_company_info(company_name, registration_number, recent = true)
      index = get_history_index(company_name, registration_number, recent)

      result = []
      index[:items].each do |info|
        detail_info = get_detailed_info(info)
        result.push(detail_info)
      end

      result
    end

    # 최근 100개 정보 중 직원 수 데이터 (생성일, 직원 수) 반환
    def get_company_count(company_name, registration_number, recent = true)
      company_info = get_company_info(company_name, registration_number, recent)
      # json_info = JSON.parse(company_info["body"])
      list = []

      for info in company_info do
        date = info[:date]
        count = info[:employee_count]
        tmp = {
          date: date,
          count: count
        }
        list.push(tmp)
      end

      list
    end

    def parse_registration_number(number)
      number.scan(/(\d{3})-(\d{2})-(\d)/).join('')
    end
  end
end