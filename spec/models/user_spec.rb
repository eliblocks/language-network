require "rails_helper"

RSpec.describe User do
  describe "#respond", :vcr do
    it "responds to the users last message" do
      user = create(:user)
      user.messages.create!(role: "user", content: "Hello")

      user.respond

      expect(user.messages.count).to eq(2)
    end
  end

  describe "#best_match", :vcr do
    it "returns the best matching user" do
      user1 = create(:user, id: 1, status: "searching")
      user2 = create(:user, id: 2, status: "searching")
      user3 = create(:user, id: 3, status: "searching")

      user1.messages.create(role: "user", content: "I'm a software engineer in NYC with experience using Ruby on Rails at several SaaS startups. Looking for a new in-person position with good benefits.")
      user2.messages.create(role: "user", content: "I'm looking for a roommate to sign a new lease in Park Slope, Brooklyn")
      user3.messages.create(role: "user", content: "I'm a founder at an early stage SaaS startup with a great product looking to bring on experienced engineers available to work in person in NYC")

      expect(user1.best_match).to eq(user3)
    end
  end
end
