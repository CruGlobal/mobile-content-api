class FavoriteToolsController < WithUserController
  before_action :validate_ids

  def create
    tool_ids.each do |tool_id|
      current_user.favorite_tools.where(tool_id: tool_id).first_or_create
    end
    render json: { "data" => current_user.favorite_tools.collect { |fav| { "type" => "resource", "id" => fav.tool_id.to_s } } }
  end

  def destroy
    current_user.favorite_tools.where(tool_id: tool_ids).delete_all
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
    error_response = missing.collect{ |tool_id| "invalid tool id: #{tool_id}" }
    render(json: error_response) if error_response.any?
  end
end
