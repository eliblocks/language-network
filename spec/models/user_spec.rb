require "rails_helper"

RSpec.describe User do
  describe "respond", :vcr do
    it "responds to the users last message" do
      user = User.create!(email: "john@example.com", first_name: "John", last_name: "Smith", password: SecureRandom.hex)
      user.messages.create!(role: "user", content: "Hello")

      user.respond

      expect(user.messages.count).to eq(2)
    end
  end
end
