class CompaniesController < ApplicationController
    before_action :authenticate_user!, only: :update

    def index
      @job_position_category_ids = params[:job_position_category_ids] || []
      @recruiting_companies = Company.appliable
      @job_position_categories = JobPositionCategory.all
      if @job_position_category_ids.present?
        @recruiting_companies = @recruiting_companies
                                  .where('job_positions.job_position_category_ids && ARRAY[?]::integer[]', @job_position_category_ids)
      end
      @recruiting_companies = @recruiting_companies
                                .includes(:job_positions, :images).to_a
                                .paginate(page: params[:page] || 1, per_page: Company::PER_PAGE)
    end

    def show
      @company = Company.includes(:images, :technical_tags).find(params[:id])
      authorize @company
      @job_positions = @company.job_positions.appliable.includes(:technical_tags)
      @job_position_categories = {}
      return if @job_positions.nil?

      @company_infos = @company.company_infos.order('registered_at DESC').to_a
      @company_info = @company_infos.first

      job_position_category_ids = @job_positions.map(&:job_position_category_ids).flatten
      @job_position_categories = JobPositionCategory.where(id: job_position_category_ids).index_by(&:id) if job_position_category_ids.join.present?
    end

    def edit
      @company = Company.find(params[:id])
      authorize @company
    end

    def update
      @company = Company.includes(:images).find(params[:id])
      authorize @company
      @images = @company.images

      ActiveRecord::Base.transaction do
        @company.assign_attributes(company_params)
        (@company.benefit_tag_list - Tag::DEFAULT_BENIFIT_TAG_NAME_BY_ICON.keys).each do |benefit_tag_name|
          Tag.company_benefit.find_or_create_by(name: benefit_tag_name)
        end
        if @company.recruit_not_apply?
          @company.notify_recruiting_inquiry(current_user)
          @company.recruit_status = :waiting
        end
        @company.save!
        update_company_images
      end

      if @company.recruit_approved?
        redirect_to edit_company_path(@company), notice: '정상적으로 수정되었습니다.'
      else
        redirect_to complete_company_inquiries_path(@company)
      end
    end

    def check
      email = params[:email].try(:strip)
      return head :not_found if email.blank?

      # NOTE: email이 valid한지 혹은 public domain인지 체크
      customer = User.new(email: email)
      customer.valid?

      if customer.errors[:email].present?
        @error = customer.errors[:email].join(', ')
        return
      end

      @domain = StringUtils.domain_name(email)

      if customer.public_domain?
        @error = I18n.t('activerecord.errors.models.user.attributes.email.invalid_domain', domain: @domain)
        return
      end

      @companies = Company.registrable(@domain).order(:name)
    end

    def auto_complete
      companies = Company.search(params[:term])
      render json: {
        results: companies.map { |t| { id: t.id, text: t.name } }
      }
    end

    private
    def update_company_images
      @company.images.where(id: params['remove_image_ids']).destroy_all if params['remove_image_ids'].present?

      params[:images]&.each do |k, file|
        image = @company.images.find_or_initialize_by(original_filename: file.original_filename)
        image.file = file
        image.display_order = k.to_i
        image.save!
      end
    end

    def company_params
      company_params = params.require(:company).permit(:address,
                                                       :home_url,
                                                       :description,
                                                       :logo,
                                                       :service_name,
                                                       :service_url,
                                                       :employees,
                                                       :funding,
                                                       :funding_year,
                                                       :revenue,
                                                       :revenue_year,
                                                       :skilled_industry_quota,
                                                       :technical_research_quota,
                                                       technical_tag_list: [],
                                                       benefit_tag_list: [],
                                                       developers: %i[icon name description url])
      company_params['developers'] = developer_params(company_params['developers'])
      company_params
    end

    def developer_params(developers)
      developers&.reject { |developer| developer['name'].blank? }
    end
  end