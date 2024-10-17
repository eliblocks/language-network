require "rails_helper"

RSpec.describe User do
  describe "#respond" do
    before { allow(Net::HTTP).to receive(:post) }
    context "New user" do
      it "responds with a welcome message" do
        user = create(:user)
        user.messages.create!(role: "user", content: "Hello")

        user.respond

        message = user.messages.last

        expect(message.role).to eq("assistant")
        expect(message.content).to include("Hello!")
        expect(message.content).not_to include("username")
      end
    end

    context "New user needs to set telegram id" do
      it "responds with a welcome message and username notice" do
        user = create(:user, telegram_id: 123)
        user.messages.create!(role: "user", content: "Hello")

        user.respond

        message = user.messages.last

        expect(message.role).to eq("assistant")
        expect(message.content).to include("Hello!")
        expect(message.content).to include("username")
      end
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

  describe "#seek", :vcr do
    it "creates a match" do
      user1 = create(:user, id: 1, status: "searching")
      user2 = create(:user, id: 2, status: "searching")
      user3 = create(:user, id: 3, status: "searching")

      user1.messages.create(role: "user", content: "I'm a software engineer in NYC with experience using Ruby on Rails at several SaaS startups. Looking for a new in-person position with good benefits.")
      user2.messages.create(role: "user", content: "I'm looking for a roommate to sign a new lease in Park Slope, Brooklyn")
      user3.messages.create(role: "user", content: "I'm a founder at an early stage SaaS startup with a great product looking to bring on experienced engineers available to work in person in NYC")

      user1.seek

      expect(user1.reload.matched_user).to eq(user3)
      expect(user1.status).to eq("matched")
      expect(user2.reload.status).to eq("searching")
      expect(user3.reload.status).to eq("matched")

      expect(user3.messages.last.role).to eq("assistant")
    end
  end
end
