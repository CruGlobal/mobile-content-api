class FavoriteToolsController < WithUserController
  before_action :validate_ids

  def index
    render json: current_user_favorite_tools_response_json
  end

  def create
    tool_ids.each do |tool_id|
      current_user.favorite_tools.where(tool_id: tool_id).first_or_create
    end
    render json: current_user_favorite_tools_response_json
  end

  def destroy
    current_user.favorite_tools.where(tool_id: tool_ids).delete_all
    render json: current_user_favorite_tools_response_json
  end

  protected

  def tool_ids
    return [] unless params[:data] && params[:data].is_a?(Array)
    return @tool_ids if @tool_ids

    @tool_ids = params[:data].collect{ |data|
      data[:id]
    }
  end

  def validate_ids
    missing = tool_ids - Resource.pluck(:id).collect(&:to_s)
    error_response = missing.collect{ |tool_id| [tool_id, "invalid tool id"] }
    render(json: { errors: error_response }) if error_response.any?
  end

  def current_user_favorite_tools_response_json
    { "data" => current_user.favorite_tools.collect { |fav| { "type" => "resource", "id" => fav.tool_id.to_s } } }
  end
end
