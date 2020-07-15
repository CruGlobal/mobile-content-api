class ResourceLanguagesController < SecureController
  before_action :get_resource, :get_language, :build_resource_language

  def show
    render json: @resource_language, include: params[:include], status: :ok
  end

  def update
    @resource_language.set_data_attributes!(data_attrs)
    render json: @resource_language, status: :ok
  end

  protected

    def get_resource
      @resource ||= Resource.find(params[:resource_id])
    end

    def get_language
      @language ||= Language.find(params[:id])
    end

    def build_resource_language
      @resource_language = ResourceLanguage.new(resource: @resource, language: @language)
    end
end
