class FavoriteToolsController < WithUserController
  before_action :validate_ids

  def index
    render_current_favorites
  end

  def create
    tool_ids.each do |tool_id|
      @user.tools << Resource.find(tool_id) unless @user.tool_ids.include?(tool_id.to_i)
    end
    render_current_favorites
  end

  def destroy
    @user.favorite_tools.where(tool_id: tool_ids).delete_all
    @user.tools.reload
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
    render(json: {errors: error_response}, status: 400) if error_response.any?
  end

  def render_current_favorites
    render json: @user.tools, include: params[:include], fields: field_params({resource: []})
  end
end
