# frozen_string_literal: true

require "page_client"

class ResourcesController < ApplicationController
  before_action :authorize!, only: [:create, :update, :push_to_onesky]

  def index
    render json: cached_index_json, status: :ok
  end

  def show
    render json: load_resource, include: params[:include], fields: field_params, status: :ok
  end

  def create
    r = Resource.create!(permitted_params)
    render json: r, status: :created
  end

  def update
    resource = load_resource
    if resource.update!(permitted_params)
      resource.set_data_attributes!(data_attrs)
    end

    render json: resource, status: :ok
  end

  def push_to_onesky
    # TODO: this could be done for individual pages when their structure is updated
    PageClient.new(load_resource, "en").push_new_onesky_translation param?("keep-existing-phrases")

    head :no_content
  end

  def suggestions
    tool_groups = []
    ToolGroup.all.each { |tool_group| tool_groups << tool_group if match_params(tool_group, params) }

    grouped_array = group_resources(tool_groups)
    render json: order_results(grouped_array), status: :ok
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
    country = params["filter"]["country"]&.upcase
    languages = params["filter"]["languages"]
    openness = params["filter"]["openness"].to_i
    confidence = params["filter"]["confidence"].to_i

    return true if no_rules_for(tool_group)
    return true if language_rule(tool_group, languages)

    # Rule Countries
    if country
      country_positive_match = tool_group.rule_countries.any? { |o| o.countries.include?(country) && !o.negative_rule }
      country_negative_match = tool_group.rule_countries.any? { |o| o.countries.include?(country) && o.negative_rule }
      return false if !country_positive_match || country_negative_match
    elsif tool_group.rule_countries.any?(&:negative_rule)
      return false
    end

    # Rule Languages
    negative_rule = tool_group.rule_languages.any?(&:negative_rule)
    language_positive_match = tool_group.rule_languages.any? { |o| (languages - o.languages).empty? && !o.negative_rule }
    language_negative_match = tool_group.rule_languages.any? { |o| !(languages - o.languages).empty? && o.negative_rule }
    return false unless negative_rule ? language_negative_match : language_positive_match

    # Rule Praxes - Openness
    openness_positive_match = tool_group.rule_praxes.any? { |o| o.openness.include?(openness) && !o.negative_rule }
    openness_negative_match = tool_group.rule_praxes.any? { |o| o.openness.include?(openness) && o.negative_rule }
    return false if !openness_positive_match || openness_negative_match

    # Rule Praxes - Confidence
    confidence_positive_match = tool_group.rule_praxes.any? { |o| o.confidence.include?(confidence) && !o.negative_rule }
    confidence_negative_match = tool_group.rule_praxes.any? { |o| o.confidence.include?(confidence) && o.negative_rule }
    return false if !confidence_positive_match || confidence_negative_match

    true
  end

  def no_rules_for(tool_group)
    tool_group.rule_languages.none? &&
      tool_group.rule_praxes.none? &&
      tool_group.rule_countries.none?
  end

  # Returns true if the tool group has a single rule with a language/s
  # present in the 'languages' array, otherwise returns false.
  def language_rule(tool_group, languages)
    return false unless tool_group.rule_languages.one?
    return false unless tool_group.rule_praxes.none? || tool_group.rule_countries.none?

    rule_languages = tool_group.rule_languages.first.languages
    (rule_languages & languages).any?
  end

  def cached_index_json
    cache_key = Resource.index_cache_key(all_resources,
      include_param: params[:include],
      fields_param: field_params)
    Rails.cache.fetch(cache_key, expires_in: 1.hour) { index_json }
  end

  def index_json
    ActiveModelSerializers::SerializableResource.new(
      all_resources.order(name: :asc),
      include: params[:include],
      fields: field_params
    ).to_json
  end

  def all_resources
    resources = if params.dig(:filter, :system)
      Resource.system_name(params[:filter][:system])
    else
      Resource.all
    end

    if params.dig(:filter, :abbreviation)
      resources = resources.where(abbreviation: params[:filter][:abbreviation])
    end

    resources
  end

  def load_resource
    Resource.find(params[:id])
  end

  def permitted_params
    permit_params(:name, :abbreviation, :manifest, :onesky_project_id, :system_id, :description, :resource_type_id, :metatool_id, :default_variant_id)
  end
end
