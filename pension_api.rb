require 'rubygems'
require 'rest-client'
require 'nokogiri'
require 'json'
require_relative './exceptions/exceptions'

class PensionApi
  BASE_API_URL = 'http://apis.data.go.kr/B552015/NpsBplcInfoInqireService'.freeze
  API_KEY = '7UmYLGjQHqLWPassQCa8xuuFiQ9ZWKGKMiQydPO7cBvLTDFL6ZGpdZZDMhxb9ZJw8CNzhf06dJSsjmply1XZMA=='.freeze
  MAXIMUM_HISTORY_INDEX = 100

  class << self
    def get_public_data_portal(action, params = {})
      url = "#{BASE_API_URL}/#{action}"
      headers = { params: params.merge(ServiceKey: API_KEY) }

      response = RestClient.get(url, headers)
      Nokogiri::XML(response)
    rescue StandardError => e
      puts(e)
      puts('공공 데이터 포탈 API 조회에서 오류가 발생했습니다.')
      raise StandardError
    end

    def get_history_infos(company_name, registration_number)
      action = 'getBassInfoSearch'
      params = {
        wkpl_nm: company_name,
        bzowr_rgst_no: parse_registration_number(registration_number),
        pageNo: '1',
        numOfRows: MAXIMUM_HISTORY_INDEX.to_s
      }

      response = get_public_data_portal(action, params)

      infos = []
      response.search('item').each do |item|
        company = item.at('wkplNm').text
        date = item.at('dataCrtYm').text
        seq = item.at('seq').text

        infos << {
          company: company,
          date: date,
          seq: seq
        }
      end

      infos.sort_by! { |idx| idx[:date] }.reverse!
    rescue StandardError => e
      puts(e)
      puts('회사 식별변호를 가져올 수 없습니다.')
      nil
    end

    def company_name_various?(infos)
      infos.map { |info| info[:company] }.uniq.count != 1
    end

    def get_employees_info(info)
      action = 'getDetailInfoSearch'
      params = {
        seq: info[:seq]
      }

      response = get_public_data_portal(action, params)

      item = response.search('item')[0]

      {
        company: info[:company],
        date: info[:date],
        employee_count: item.at('jnngpCnt').text.to_i,
        total_paid_pension: item.at('crrmmNtcAmt').text.to_i
      }
    rescue StandardError => e
      puts(e)
      puts('회사 세부 정보를 가져올 수 없습니다.')
      nil
    end

    def get_company_info(company)
      name = company.registration_name || company.name

      company_history_infos = get_history_infos(name, company.registration_number)
      raise Exceptions::NotFoundError, '조회 결과가 없습니다. 사업자등록번호나 사업자등록상호명을 확인해주세요.' if company_history_infos.first.nil?

      is_various = company_name_various? company_history_infos
      raise Exceptions::VariousCompanyNameError, '비슷한 이름의 여러 회사들이 검색됩니다. 국민연금공단에 등록된 기업 상호명을 업데이트 해주세요.' if company.registration_name.nil? && is_various

      company_infos = []
      company_history_infos = company_history_infos.select { |item| item[:company] == company.registration_name } if is_various
      company_history_infos.each do |info|
        employees_info = get_employees_info(info)
        company_infos.push(employees_info)
      end
      raise Exceptions::InvalidRegistrationNameError, '국민연금공단에 등록된 기업 상호명이 정확하지 않습니다.' if company_infos[0].nil?

      puts(company_infos)
      company_infos
    rescue Exceptions::Base => e
      puts(e)
      nil
    end

    def parse_registration_number(number)
      number.scan(/(\d{3})-(\d{2})-(\d)/).join('')
    end
  end
end