class CreateCompanyInfoJob < ApplicationJob
  queue_as :default

  def perform(args)
    company = Company.find(args[:company_id])
    if company.registration_number.nil?
      Rails.logger.error('사업자 등록 번호가 없습니다.')
      return
    end

    result = nil
    company_info = PensionApi.get_company_info(company, true)
    if company_info == 'EMPTY'
      Rails.logger.error('조회 결과가 없습니다.')

    elsif company_info == 'MULTI_VALUES'
      Rails.logger.error('비슷한 이름의 여러 회사들이 검색됩니다. 국민연금공단에 등록된 기업 상호명을 추가로 업데이트 해주세요.')

    elsif company_info == 'REGISTRATION_NAME_NOT_CORRECT'
      Rails.logger.error('국민연금공단에 등록된 기업 상호명이 정확하지 않습니다.')

    else
      company_info = company_info[0]

      data_registered_at = Time.zone.strptime(company_info[:date], '%Y%m')
      begin
        result = company.company_infos.create!(data_registered_at: data_registered_at, employee_count: company_info[:employee_count], total_paid_pension: company_info[:total_paid_pension])
      rescue StandardError => e
        Rails.logger.error(e)
        Rails.logger.error('이미 업데이트 되어 있는 정보 입니다.')
      end
    end

    result
  end
end