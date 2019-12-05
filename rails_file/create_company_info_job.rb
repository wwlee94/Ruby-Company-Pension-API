class CreateCompanyInfoJob < ApplicationJob
  queue_as :default

  def perform(company_id, using_latest_data = true)
    company = Company.find(company_id)
    raise HeraExceptions::InvalidRegistrationNumberError, '사업자 등록 번호가 없습니다.' if company.registration_number.nil?

    company_infos = PensionApi.get_company_info(company)

    return unless company_infos

    if using_latest_data
      create_company_infos_by! company, company_infos[0]
    else
      company_infos.each do |company_info|
        create_company_infos_by! company, company_info
      end
    end

  rescue HeraExceptions::Base => e
    Rollbar.error(e)
    Rails.logger.error(e)
    nil
  end

  def create_company_infos_by!(company, company_info)
    registered_at = Time.zone.strptime(company_info[:date], '%Y%m')
    company.company_infos.create!(registered_at: registered_at, employees_count: company_info[:employees_count], total_paid_pension: company_info[:total_paid_pension])

  rescue ActiveRecord::RecordInvalid => e
    Rollbar.error(e)
    Rails.logger.error(e)
    Rails.logger.error(company_info[:company] + ' 기업의 ' + company_info[:date] + ' 일자 데이터는 이미 저장되어 있습니다.')
    nil
  rescue StandardError => e
    Rollbar.error(e)
    Rails.logger.error(e)
    Rails.logger.error('오류가 발생하여 회사 정보를 업데이트하지 못하였습니다.')
    nil
  end
end