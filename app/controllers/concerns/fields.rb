module Fields
  private

  def field_params
    return {} unless params[:fields]

    params[:fields].transform_values do |field_value|
      field_value.split(",")
    end.to_unsafe_h
  end
end
