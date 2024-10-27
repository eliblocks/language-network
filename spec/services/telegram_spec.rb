require "rails_helper"

RSpec.describe Telegram do
  describe "send_message" do
    it "is successful", :vcr do
      response = described_class.send_message("5899443915", "Hello")

      expect(response).to be_a Net::HTTPSuccess
    end
  end
end
