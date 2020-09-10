# frozen_string_literal: true

require "acceptance_helper"

resource "Tips" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }
  let(:resource) { Resource.first }
  let(:resource2) { Resource.second }

  let(:structure) { FactoryBot.attributes_for(:tip)[:structure] }

  post "tips" do
    requires_authorization

    it "create tip" do
      expect {
        do_request data: {type: "tip", attributes: {name: "name", structure: structure, resource_id: resource.id}}
      }.to change { Tip.count }.by(1)

      expect(status).to eq(201)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
      expect(Tip.last.name).to eq("name")
      expect(Tip.last.structure).to eq(structure)
      expect(Tip.last.resource).to eq(resource)
      expect(response_headers["Location"]).to eq("tips/#{Tip.last.id}")
    end

    context("tip exists") do
      let!(:tip) { FactoryBot.create(:tip, name: "name", structure: structure, resource: resource) }

      it "make a new tip on a different resource" do
        expect {
          do_request data: {type: "tip", attributes: {name: "name", structure: structure, resource_id: resource2.id}}
        }.to change { Tip.count }.by(1)
        expect(Tip.last.name).to eq("name")
        expect(Tip.last.structure).to eq(structure)
        expect(Tip.last.resource).to eq(resource2)
      end

      it "checks tip name unique per resource" do
        # make a new tip on resource2 with the same name that should error
        expect {
          do_request data: {type: "tip", attributes: {name: "name", structure: structure, resource_id: resource.id}}
        }.to_not change { Tip.count }
        expect(response_body).to eq(%({"errors":[{"source":{"pointer":"/data/attributes/id"},"detail":"Validation failed: Name has already been taken"}]}))
      end
    end
  end

  put "tips/:id" do
    let(:t) { FactoryBot.create(:tip, structure: structure, resource: resource) }
    let(:id) { t.id }
    let(:attrs) { {structure: structure} }
    let(:resource) { Resource.first }
    let(:structure2) do
      %(<tip xmlns="https://mobile-content-api.cru.org/xmlns/training"
					xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
						<pages>
								<page>
										<content:paragraph>
												<content:text />
										</content:paragraph>
										<content:paragraph>
												<content:text />
										</content:paragraph>
										<content:text />
								</page>
						</pages>
				</tip>)
    end

    requires_authorization

    it "edit tip" do
      do_request data: {attributes: {structure: structure2}}

      expect(status).to eq(200)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
      expect(t.reload.structure).to eq(structure2)
    end
  end
end
