class ToolGroupsController < ApplicationController
  before_action :authorize!

  def index
    render json: ToolGroup.all.order(name: :asc), status: :ok
  end

  def create
    create_tool_group
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors }, status: :unprocessable_entity
  end

  def show
    render json: load_tool_group, status: :ok
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
