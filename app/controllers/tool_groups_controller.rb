class ToolGroupsController < ApplicationController
  before_action :authorize!
  before_action :convert_hyphen_to_dash, only: [:create, :update]

  def index
    render json: tool_groups_ordered_by_name, include: params[:include], fields: field_params, status: :ok
  end

  def create
    create_tool_group
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors(e)}, status: :unprocessable_entity
  end

  def create_tool
    ResourceToolGroup.create!(
      tool_group_id: params[:tool_group_id],
      resource_id: params[:data][:attributes][:resource_id],
      suggestions_weight: params[:data][:attributes]["suggestions-weight"]
    )

    tool_group = ToolGroup.find(params[:tool_group_id])
    response.headers["Location"] = "tool_groups/#{tool_group.id}"
    render json: tool_group, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors(e)}, status: :unprocessable_entity
  end

  def update_tool
    existing = ResourceToolGroup.find(params[:id])

    existing.update!(
      resource_id: params[:data][:attributes][:resource_id],
      suggestions_weight: params[:data][:attributes][:suggestions_weight]
    )
    render json: existing, status: :accepted
  end

  def delete_tool
    resource_tool_group = ResourceToolGroup.find(params[:id])
    resource_tool_group.destroy!
    head :no_content
  end

  def show
    render json: load_tool_group, include: params[:include], fields: field_params, status: :ok
  end

  def destroy
    tool_group = ToolGroup.find(params[:id])
    tool_group.destroy!
    head :no_content
  end

  def update
    update_tool_group
  end

  private

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
