# frozen_string_literal: true

def mock_auth
  allow(AuthToken).to receive(:find_by).and_return(AuthToken.new)
end
