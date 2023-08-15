class ToolGroupsController < ApplicationController
  before_action :authorize!
  before_action :convert_hyphen_to_dash, only: [:create, :update]

  def index
    render json: tool_groups_ordered_by_name, include: params[:include], fields: field_params, status: :ok
  end

  def create
    create_tool_group
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_entity
  end

  def create_tool
    tool_group_id = params[:tool_group_id].to_i
    resource_id = params.dig(:data, :relationships, :tool, :data, :id).to_i
    suggestions_weight = params.dig(:data, :attributes, "suggestions-weight").to_f

    resource_tool_group = ResourceToolGroup.create!(
      tool_group_id: tool_group_id,
      resource_id: resource_id,
      suggestions_weight: suggestions_weight
    )

    response.headers["Location"] = "tool-groups/#{resource_tool_group.id}"
    render json: resource_tool_group, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_entity
  end

  def update_tool
    existing = resource_tool_group

    existing.update!(
      resource_id: params[:data][:relationships][:tool][:data][:id],
      suggestions_weight: params[:data][:attributes]["suggestions-weight"]
    )
    render json: existing, status: :accepted
  end

  def delete_tool
    resource_tool_group.destroy!
  end

  def show
    render json: load_tool_group, include: params[:include], fields: field_params, status: :ok
  end

  def destroy
    tool_group = ToolGroup.find(params[:id])
    tool_group.destroy!
    head :no_content
  rescue ActiveRecord::RecordNotFound => e
    render json: formatted_errors("record_not_found", e), status: :not_found
  end

  def update
    update_tool_group
  end

  private

  def resource_tool_group
    ResourceToolGroup.where(tool_group_id: params[:tool_group_id]).find(params[:id])
  end

  def tool_groups_ordered_by_name
    ToolGroup.order(name: :asc)
  end

  def create_tool_group
    created = ToolGroup.create!(permit_params(:name, :suggestions_weight))
    response.headers["Location"] = "tool_groups/#{created.id}"
    render json: created, status: :created
  end

  def update_tool_group
    existing = ToolGroup.find(params[:id])
    existing.update!(permit_params(:name, :suggestions_weight))
    render json: existing, status: :accepted
  end

  def load_tool_group
    ToolGroup.find(params[:id])
  end
end
