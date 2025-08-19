# frozen_string_literal: true

require "acceptance_helper"

resource "FollowUps" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"
  let(:raw_post) { params.to_json }

  post "follow_ups/" do
    let(:data) do
      {type: type,
       attributes: {name: "Billy Bob", email: "bob@test.com", language_id: 2, destination_id: 1}}
    end

    it "create a subscriber" do
      allow(RestClient).to receive(:post).and_return(instance_double(RestClient::Response, code: 201))

      do_request data: data

      expect(status).to be(204)
      expect(response_body).to be_empty
    end

    context "with salesforce destination" do
      let(:salesforce_destination) { Destination.salesforce.first! }
      let(:data) do
        {type: type,
         attributes: {name: "Jane Doe", email: "jane@test.com", language_id: 2, destination_id: salesforce_destination.id}}
      end

      before do
        # Stub Salesforce authentication
        auth_response = instance_double(RestClient::Response,
          body: {access_token: "fake_token"}.to_json,
          code: 200)
        allow(RestClient).to receive(:post)
          .with(/token/, anything, anything)
          .and_return(auth_response)

        # Stub Salesforce data event API
        data_response = instance_double(RestClient::Response,
          code: 200,
          headers: {"content-type" => "application/json"},
          body: "")
        allow(RestClient).to receive(:post)
          .with(/dataevents/, anything, anything)
          .and_return(data_response)
      end

      it "creates subscriber via salesforce" do
        expect { do_request data: data }.to change(FollowUp, :count).by(1)

        expect(status).to be(204)
        expect(response_body).to be_empty

        # Verify the follow-up was created with correct attributes
        follow_up = FollowUp.last
        expect(follow_up.email).to eq("jane@test.com")
        expect(follow_up.name).to eq("Jane Doe")
        expect(follow_up.language_id).to eq(2)
        expect(follow_up.destination_id).to eq(salesforce_destination.id)

        # Verify auth call was made
        expect(RestClient).to have_received(:post).with(
          /token/,
          anything,
          {content_type: :json, accept: :json}
        )

        # Verify data event call was made
        expect(RestClient).to have_received(:post).with(
          /dataevents/,
          anything,
          hash_including("Authorization" => "Bearer fake_token")
        )
      end
    end
  end
end
