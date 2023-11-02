module Fields
  private

  def field_params(default = {})
    return default unless params[:fields]

    params[:fields].to_unsafe_h.transform_values do |field_value|
      field_value.split(",")
    end
  end
end
