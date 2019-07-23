# frozen_string_literal: true

class CustomManifestsController < SecureController
  skip_before_action :authorize!, only: [:show]

  def create
    manifest = find_manifest
    if manifest
      update_manifest(manifest)
    else
      create_manifest
    end
  end

  def update
    manifest = find_manifest
    update_manifest(manifest)
  end

  def destroy
    manifest = find_manifest
    manifest.destroy!
    head :no_content
  end

  def show
    manifest = find_manifest
    render json: manifest, status: :ok
  end

  private

  def find_manifest
    if params[:id]
      CustomManifest.find(params[:id])
    else
      CustomManifest.find_by(language_id: data_attrs[:language_id], resource_id: data_attrs[:resource_id])
    end
  end

  def create_manifest
    manifest = CustomManifest.create!(permit_params(:language_id, :resource_id, :structure))
    render json: manifest, status: :created, location: custom_manifest_path(manifest)
  end

  def update_manifest(manifest)
    manifest.update!(permit_params(:structure))
    render json: manifest, status: :ok
  end
end
