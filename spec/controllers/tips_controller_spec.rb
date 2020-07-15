# frozen_string_literal: true

require "rails_helper"

describe TipsController, type: :controller do
  let(:resource) { Resource.first }
  let(:resource2) { Resource.second }
  let!(:auth_token) { FactoryBot.create(:auth_token) }

  before do
    request.headers["Authorization"] = auth_token.token
  end

  let(:structure) do
    %(<tip xmlns="https://mobile-content-api.cru.org/xmlns/training"
        xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
          <pages>
              <page>
                  <content:paragraph>
                      <content:text />
                  </content:paragraph>
                  <content:text />
              </page>
          </pages>
      </tip>)
  end

  context "#create" do
    it "creates a new tip" do
      expect {
        post :create, {params: {data: {attributes: {name: "name", structure: structure, resource_id: resource.id}}}}
      }.to change { Tip.count }.by(1)
      expect(Tip.last.name).to eq("name")
      expect(Tip.last.structure).to eq(structure)
      expect(Tip.last.resource).to eq(resource)
    end

    it "validates name uniqueness by resource" do
      expect {
        post :create, {params: {data: {attributes: {name: "name", structure: structure, resource_id: resource.id}}}}
      }.to change { Tip.count }.by(1)
      expect(Tip.last.name).to eq("name")
      expect(Tip.last.structure).to eq(structure)
      expect(Tip.last.resource).to eq(resource)

      # make a new tip on a different resource
      expect {
        post :create, {params: {data: {attributes: {name: "name", structure: structure, resource_id: resource2.id}}}}
      }.to change { Tip.count }.by(1)
      expect(Tip.last.name).to eq("name")
      expect(Tip.last.structure).to eq(structure)
      expect(Tip.last.resource).to eq(resource2)

      # make a new tip on resource2 with the same name that should error
      expect {
        post :create, {params: {data: {attributes: {name: "name", structure: structure, resource_id: resource2.id}}}}
      }.to_not change { Tip.count }
      expect(response.body).to eq(%({"errors":[{"source":{"pointer":"/data/attributes/id"},"detail":"Validation failed: Name has already been taken"}]}))
    end
  end
end
