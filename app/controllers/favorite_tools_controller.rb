class FavoriteToolsController < WithUserController
  before_action :validate_ids

  def index
    render_current_favorites
  end

  def create
    tool_ids.each do |tool_id|
      current_user.tools << Resource.find(tool_id) unless current_user.tool_ids.include?(tool_id.to_i)
    end
    render_current_favorites
  end

  def destroy
    current_user.favorite_tools.where(tool_id: tool_ids).delete_all
    current_user.tools.reload
    render_current_favorites
  end

  protected

  def tool_ids
    return [] unless params[:data]&.is_a?(Array)
    return @tool_ids if @tool_ids

    @tool_ids = params[:data].collect { |data|
      data[:id].to_s
    }
  end

  def validate_ids
    missing = tool_ids - Resource.pluck(:id).collect(&:to_s)
    error_response = missing.collect { |tool_id| {"code" => "invalid_tool", "meta" => {"tool_id" => tool_id}} }
    render(json: {errors: error_response}) if error_response.any?
  end

  def render_current_favorites
    render json: current_user.tools, each_serializer: ResourceFavoritedSerializer
  end
end
