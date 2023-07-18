class ToolGroupsController < ApplicationController
  before_action :authorize!

  def index
    include = {}
    fields = {}

    include = params[:include]&.split(",") if params[:include]
    fields = get_fields(params[:fields]) if params[:fields]

    render json: tool_groups_ordered_by_name, include: include, fields: fields, status: :ok
  end

  def create
    create_tool_group
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors(e)}, status: :unprocessable_entity
  end

  def show
    include = params[:include]&.split(",")
    render json: load_tool_group, include: include, fields: field_params, status: :ok
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

  def formatted_errors(error)
    error.record.errors.map do |attribute, errors|
      errors.map { |error_message| {detail: "#{attribute} #{error_message}"} }
    end.flatten
  end

  def get_fields(fields)
    array = fields&.split('&') || [fields]

    result = {}
    json_hash = {}

    array.each do |item|
      match = item.match(/\Afields\[(.+)\]=(.+)\z/)
      if match
        key = match[1]
        value = match[2]
        result[key] = value
      end
    end

    result.each do |key, value|
      json_hash[key] = value.include?(',') ? value.split(',') : [value]
    end

    json_hash
  end
end
