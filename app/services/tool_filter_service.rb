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
      country = params["filter"]["country"]&.upcase if params["filter"]["country"].present?
      languages = params["filter"]["language"] if params["filter"]["language"].present?
      openness = params["filter"]["openness"].to_i if params["filter"]["openness"].present?
      confidence = params["filter"]["confidence"].to_i if params["filter"]["confidence"].present?
    end

    if country.nil? & languages.nil? & openness.nil? & confidence.nil?
      return no_rules_for(tool_group)
    end

    return true if no_rules_for(tool_group)

    # Rule Countries
    if tool_group.rule_countries.any? && !country.nil?
      if tool_group.rule_countries.any? { |o| o.countries.include?(country) && o.negative_rule }
        return false
      elsif tool_group.rule_countries.any? { |o| o.countries.exclude?(country) && !o.negative_rule }
        return false
      end
    elsif !tool_group.rule_countries.any? && !country.nil? && !tool_group.rule_languages.any?
      return false
    end

    # Rule Languages
    if tool_group.rule_languages.any? && languages
      if tool_group.rule_languages.any? { |o| (languages & tool_group.rule_languages.first.languages).empty? && !o.negative_rule }
        return false
      elsif tool_group.rule_languages.any? { |o| (languages - tool_group.rule_languages.first.languages).empty? && o.negative_rule }
        return false
      end
    elsif tool_group.rule_languages.any? && !languages.nil?
      return false
    end

    # Rule Praxes
    if (openness || confidence) && tool_group.rule_praxes.any?
      # Openness
      if openness
        openness_positive_match = tool_group.rule_praxes.any? { |o| o.openness.include?(openness) && !o.negative_rule }
        openness_negative_match = tool_group.rule_praxes.any? { |o| o.openness.include?(openness) && o.negative_rule }
        return false if !openness_positive_match || openness_negative_match
      end

      # Confidence
      if confidence
        confidence_positive_match = tool_group.rule_praxes.any? { |o| o.confidence.include?(confidence) && !o.negative_rule }
        confidence_negative_match = tool_group.rule_praxes.any? { |o| o.confidence.include?(confidence) && o.negative_rule }
        return false if !confidence_positive_match || confidence_negative_match
      end
    elsif (openness || confidence) && !tool_group.rule_praxes.any?
      return false
    end

    true
  end

  def no_rules_for(tool_group)
    tool_group.rule_languages.none? &&
      tool_group.rule_praxes.none? &&
      tool_group.rule_countries.none?
  end
end
