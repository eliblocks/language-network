require "rails_helper"

RSpec.describe SearchJob do
  it "calls update status", :vcr do
    user = create(:user)

    expect { described_class.perform_later(user.id) }.not_to raise_error
  end
end
