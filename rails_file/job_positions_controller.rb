class JobPositionsController < ApplicationController
  include ActionTrackings
  def show
    @job_position = JobPosition.includes(:technical_tags).find(params[:id])

    authorize @job_position
    @job_position_category_name = JobPositionCategory.where(id: @job_position.job_position_category_ids).pluck(:name)
    @team_environment = @job_position.team_environment
    @company = @job_position.company
    @company_developers = @company.developers
    @company_info = @company.company_infos.order('registered_at DESC').first

    create_action_tracking(job_position_id: @job_position.id, event: :visit_job_position_show, data: { count: 1 })

    if user_signed_in?
      notification = current_user.notifications.new_job_offer.where("context->>'job_position_id' = '?'", @job_position.id).first
      notification&.mark_as_read for: current_user
      if params[:job_application_id]
        job_application = current_user.job_applications.find_by(id: params[:job_application_id], job_position_id: @job_position.id)
        job_application&.viewed_by_applicant
      end
    end

    @recommended_job_positions = @job_position.adjacent_job_positions
    @job_categories_by_id = JobPositionCategory.all.index_by(&:id)
  end

  def index
    @filter_params = filter_params
    @job_positions = JobPosition
                        .appliable
                        .includes(:company, :technical_tags)

    if @filter_params[:company_ids].present?
      @job_positions = @job_positions.where(company_id: @filter_params[:company_ids])
      @companies = Company.where(id: @filter_params[:company_ids])
    end

    @job_positions = @job_positions.where('companies.address SIMILAR TO ?', "%(#{@filter_params[:cities].join('|')})%") if @filter_params[:cities].present?
    @job_positions = @job_positions.where('job_positions.job_position_category_ids && ARRAY[?]::integer[]', @filter_params[:job_category_ids]) if @filter_params[:job_category_ids].present?

    if @filter_params[:min_career].present?
      min_career = @filter_params[:min_career].to_i
      if min_career.zero?
        @job_positions = @job_positions.where(career_option: %i[unrelated newcomer])
      elsif min_career.positive?
        @job_positions = @job_positions.where('(career_option = ?) OR (career_option = ? AND ( LOWER(career_range) <= ? AND ? <= UPPER(career_range)) )',
                                              JobPosition.career_options[:unrelated],
                                              JobPosition.career_options[:experience],
                                              min_career,
                                              min_career)
      end
    end

    if @filter_params[:tags].present?
      @job_positions = @job_positions
                          .tagged_with(@filter_params[:tags], on: :technical_tags, any: true)
    end

    @job_positions = @job_positions
                        .order('companies.display_order asc')
                        .order('job_positions.updated_at desc')
                        .paginate(page: params[:page] || 1, per_page: JobPosition::PER_PAGE)

    @job_categories_by_id = JobPositionCategory.all.index_by(&:id)

    return unless user_signed_in?

    @job_position_filter = current_user
                              .job_position_filters
                              .find_by(min_career: @filter_params[:min_career],
                                      cities: @filter_params[:cities].to_a,
                                      company_ids: @filter_params[:company_ids].to_a,
                                      tags: @filter_params[:tags].to_a,
                                      job_category_ids: @filter_params[:job_category_ids].to_a)
  end

  def address
    address_infos = AddressInfo.search(params[:q])
    render json: {
      results: address_infos.map { |address_info| { address: address_info.address, city: address_info.city } }
    }
  end

  private

  def filter_params
    return {} if params[:job_position].nil?

    params.require(:job_position).permit(:min_career,
                                          cities: [],
                                          company_ids: [],
                                          tags: [],
                                          job_category_ids: [])
  end
end