require 'rubygems'
require 'rest-client'
require 'nokogiri'
require 'json'

class PensionApi
  BASE_API_URL = 'http://apis.data.go.kr/B552015/NpsBplcInfoInqireService'.freeze
  API_KEY = '7UmYLGjQHqLWPassQCa8xuuFiQ9ZWKGKMiQydPO7cBvLTDFL6ZGpdZZDMhxb9ZJw8CNzhf06dJSsjmply1XZMA=='.freeze
  MAXIMUM_HISTORY_INDEX = 100

  class << self
    def get_history_infos(company_name, registration_number)
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
        Rails.logger.error('PensionAPI Error : 회사 식별변호를 가져올 수 없습니다.')
        return
      end

      response = Nokogiri::XML(response)

      infos = {
        items: []
      }
      response.search('item').each do |item|
        company = item.at('wkplNm').text
        date = item.at('dataCrtYm').text
        seq = item.at('seq').text

        infos[:items] << {
          company: company,
          date: date,
          seq: seq
        }
      end

      infos[:items] = infos[:items].sort_by { |idx| idx[:date] }.reverse

      infos
    end

    def is_multi_values(infos)
      is_multi = false
      first_company_name = infos[:items].first[:company]

      infos[:items].each_with_index do |info, idx|
        next if idx.zero?
        next if first_company_name == info[:company]

        is_multi = true
      end
      is_multi
    end

    def get_detailed_info(info)
      url = "#{BASE_API_URL}/getDetailInfoSearch"
      headers = {
        params: {
          ServiceKey: API_KEY,
          seq: info[:seq]
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
        company: info[:company],
        date: info[:date],
        employee_count: item.at('jnngpCnt').text.to_i,
        total_paid_pension: item.at('crrmmNtcAmt').text.to_i
      }
    end

    def get_company_info(company, recent = true)
      name = company.registration_name || company.name

      infos = get_history_infos(name, company.registration_number)
      return 'EMPTY' if infos[:items].first.nil?

      is_multi = is_multi_values(infos)
      return 'MULTI_VALUES' if company.registration_name.nil? && is_multi

      result = []
      if is_multi
        infos[:items].each do |info|
          next if company.registration_name != info[:company]

          detail_info = get_detailed_info(info)
          result.push(detail_info)
        end
        return 'REGISTRATION_NAME_NOT_CORRECT' if result[0].nil?
      else
        infos[:items].each do |info|
          detail_info = get_detailed_info(info)
          result.push(detail_info)
        end
      end

      if recent
        recent_info = result[0]
        result = []
        result.push(recent_info)
      end

      puts(result)
      result
    end

    def parse_registration_number(number)
      number.scan(/(\d{3})-(\d{2})-(\d)/).join('')
    end
  end
end