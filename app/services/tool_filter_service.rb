# frozen_string_literal: true

class ToolFilterService
  def initialize(params)
    @params = params
  end

  def call
    tool_groups = []
    ToolGroup.all.each { |tool_group| tool_groups << tool_group if match_params(tool_group, @params) }
    grouped_array = group_resources(tool_groups)
    order_results(grouped_array)
  end

  private

  def order_results(grouped_array)
    result = grouped_array.map do |key, values|
      counter = values.size
      sum = values.sum { |o| o[:tool_group_suggestions_weight] * o[:resource_tool_group_suggestions_weight] }
      average = sum / counter
      [Resource.find(key), average]
    end

    sorted_result = result.sort_by { |subarray| -subarray[1] }
    sorted_result.map { |subarray| subarray[0] }
  end

  def group_resources(tool_groups)
    result = tool_groups.flat_map do |tool_group|
      tool_group.resource_tool_groups.map do |resource|
        {
          tool_group_suggestions_weight: tool_group.suggestions_weight,
          resource_id: resource.resource_id,
          resource_tool_group_suggestions_weight: resource.suggestions_weight
        }
      end
    end

    result.group_by { |hash| hash[:resource_id] }
  end

  def match_params(tool_group, params)
    if params.has_key?(:filter)
      country = params.dig("filter", "country")&.upcase
      languages = params.dig("filter", "language")
      openness = params.dig("filter", "openness")&.to_i
      confidence = params.dig("filter", "confidence")&.to_i
    end

    # Country Rules
    if tool_group.rule_countries.any? { |o| o.negative_rule && o.countries.include?(country) }
      return false
    elsif tool_group.rule_countries.any? { |o| !o.negative_rule && o.countries.exclude?(country) }
      return false
    end

    # Language Rules
    if tool_group.rule_languages.any? { |o| !o.negative_rule && (languages & o.languages).empty? }
      return false
    elsif tool_group.rule_languages.any? { |o| o.negative_rule && (languages - o.languages).empty? }
      return false
    end

    # Praxis Rules
    if tool_group.rule_praxes.any? { |o| o.openness.present? && o.negative_rule && o.openness.include?(openness) }
      return false
    elsif tool_group.rule_praxes.any? { |o| o.openness.present? && !o.negative_rule && o.openness.exclude?(openness) }
      return false
    elsif tool_group.rule_praxes.any? { |o| o.confidence.present? && o.negative_rule && o.confidence.include?(confidence) }
      return false
    elsif tool_group.rule_praxes.any? { |o| o.confidence.present? && !o.negative_rule && o.confidence.exclude?(confidence) }
      return false
    end

    true
  end
end
