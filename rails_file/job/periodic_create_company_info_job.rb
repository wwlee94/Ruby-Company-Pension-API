# 하루에 한 번 (05:00 AM) company_id%30 의 값이 오늘 날짜와 같은 회사의 연금 지출 총액 및 직원수를 업데이트 해주는 잡 (한달이면 모든 회사 업데이트 가능)
class PeriodicCreateCompanyInfoJob < ApplicationJob
    queue_as :default

    def perform
        today = Time.current.day
        return nil if today > 30

        companies = Company.all.to_a
        companies.select! { |company| company.id % 30 == today }
        companies.each do |company|
        CreateCompanyInfoJob.perform_now(company.id)
        end
        nil
    end
end