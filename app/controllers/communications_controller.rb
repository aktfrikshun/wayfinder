class CommunicationsController < ApplicationController
  before_action :require_admin!
  before_action :set_communication, only: %i[show edit update destroy]

  def index
    @query = params[:q].to_s.strip
    @communications = Communication.includes(child: :parent).order(received_at: :desc)

    return if @query.blank?

    @communications = @communications.joins(child: :parent).where(
      "communications.subject ILIKE :q OR communications.from_email ILIKE :q OR communications.from_name ILIKE :q OR " \
      "communications.source ILIKE :q OR communications.ai_status ILIKE :q OR children.name ILIKE :q OR parents.email ILIKE :q",
      q: "%#{@query}%"
    )
  end

  def show; end

  def new
    @communication = Communication.new(received_at: Time.current, ai_status: "pending")
  end

  def edit; end

  def create
    attrs = prepared_communication_params
    return render(:new, status: :unprocessable_entity) unless attrs

    @communication = Communication.new(attrs)

    if @communication.save
      redirect_to @communication, notice: "Communication created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    attrs = prepared_communication_params
    return render(:edit, status: :unprocessable_entity) unless attrs

    if @communication.update(attrs)
      redirect_to @communication, notice: "Communication updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @communication.destroy
    redirect_to communications_path, notice: "Communication deleted."
  end

  private

  def set_communication
    @communication = Communication.find(params[:id])
  end

  def communication_params
    params.require(:communication).permit(
      :child_id,
      :source,
      :from_email,
      :from_name,
      :subject,
      :received_at,
      :body_text,
      :body_html,
      :ai_status,
      :ai_error,
      :raw_payload,
      :ai_raw_response,
      :ai_extracted,
      correspondent_ids: []
    )
  end

  def prepared_communication_params
    attrs = communication_params.to_h
    attrs["correspondent_ids"] ||= []
    attrs["correspondent_ids"] = attrs["correspondent_ids"].reject(&:blank?)

    %w[raw_payload ai_raw_response ai_extracted].each do |field|
      raw_value = attrs[field]
      next unless raw_value.is_a?(String)

      compact = raw_value.strip
      attrs[field] =
        if compact.blank?
          field == "raw_payload" ? {} : nil
        else
          JSON.parse(compact)
        end
    end

    attrs
  rescue JSON::ParserError => e
    @communication ||= params[:id] ? Communication.find(params[:id]) : Communication.new
    @communication.assign_attributes(communication_params)
    @communication.errors.add(:base, "Invalid JSON input: #{e.message}")
    nil
  end
end
