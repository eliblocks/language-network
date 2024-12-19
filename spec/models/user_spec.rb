require "rails_helper"

RSpec.describe User do
  describe "#admin?" do
    let(:user) { build(:user) }

    it "is usually false" do
      expect(user.admin?).to eq(false)
    end

    it "is true when user role is set to admin" do
      user.role = "admin"

      expect(user.admin?).to eq(true)
    end
  end

  describe "#username" do
    it "is the email for a web user" do
      user = build(:user)

      expect(user.username).to eq(user.email)
    end

    it "is the telegram username for a telegram user" do
      user = build(:telegram_user)

      expect(user.username).to eq(user.telegram_username)
    end

    it "is the instagram username for an instagram user" do
      user = build(:instagram_user)

      expect(user.username).to eq(user.instagram_username)
    end
  end

  describe "#intro_name" do
    it "is the first name when there is a first name" do
      user = build(:user)

      expect(user.intro_name).to eq(user.first_name)
    end

    it "is the username there is no first name" do
      user = build(:instagram_user, first_name: nil)

      expect(user.intro_name).to eq(user.username)
    end
  end


  describe "#name" do
    let(:user) { build(:user, first_name: "John", last_name: "Smith") }

    it "returns the full name when there is a first and last name" do
      expect(user.name).to eq("John Smith")
    end

    it "returns the first name with only a first name" do
      user.last_name = nil
      expect(user.name).to eq("John")
    end

    it "returns an empty string when there is no name" do
      user = build(:user, first_name: nil, last_name: nil)

      expect(user.name).to eq("")
    end
  end

  describe "#service" do
    it "returns nil for web user" do
      expect(build(:user).service).to eq("Web")
    end

    it "returns telegram for a telegram user" do
      expect(build(:telegram_user).service).to eq("Telegram")
    end

    it "returns instagram for a instagram user" do
      expect(build(:instagram_user).service).to eq("Instagram")
    end
  end

  describe "#searching" do
    it "is false by default" do
      expect(build(:user).searching?).to eq(false)
    end

    it "is true when status is searching" do
      expect(build(:user, status: "searching").searching?).to eq(true)
    end
  end

  describe "#profile_link" do
    it "is a the telegram link for a telegram user" do
      user = build(:telegram_user)
      link = "<a href='tg://user?id=#{user.telegram_id}'>#{user.name}</a>"

      expect(user.profile_link).to eq(link)
    end

    it "is the instagram link for an instagram user" do
      user = build(:instagram_user)
      link = "https://www.instagram.com/#{user.instagram_username}"

      expect(user.profile_link).to eq(link)
    end
  end

  describe "#matched_user" do
    it "returns the most recently matched user" do
      searching_user = create(:user)
      matched_user = create(:user)

      Match.create(searching_user:, matched_user:)

      expect(searching_user.matched_user).to eq(matched_user)
      expect(matched_user.matched_user).to eq(searching_user)
    end
  end

  describe "#respond" do
    before { allow(Net::HTTP).to receive(:post) }

    it "responds with a welcome message" do
      user = create(:telegram_user)
      user.messages.create!(role: "user", content: "Hello")

      user.respond

      message = user.messages.last

      expect(message.role).to eq("assistant")
      expect(message.content).to include("Hello!")
      expect(message.content).not_to include("username")
    end
  end

  describe "#update_status", :vcr do
    it "sets the status field based on the conversation" do
      user = create(:user)

      expect(user.status).to eq("initial")

      user.messages.create(role: "user", content: "Hello")
      user.messages.create(role: "assistant", content: Prompts.welcome_message)

      user.update_status

      expect(user.reload.status).to eq("drafting")

      user.messages.create(role: "user", content: "I'm a software engineer in NYC with experience using Ruby on Rails at several SaaS startups. Looking for a new in-person position with good benefits and work life balance.")
      user.messages.create(role: "assistant", content: "Great! I'll let you know if I find someone looking for an engineer with your skills")

      user.update_status

      expect(user.reload.status).to eq("searching")
    end
  end

  describe "#search", :vcr do
    it "creates a match" do
      user1 = create(:user, id: 1, status: "searching")
      user2 = create(:user, id: 2, status: "searching")
      user3 = create(:user, id: 3, status: "searching")

      user1.messages.create(role: "user", content: "I'm a software engineer in NYC with experience using Ruby on Rails at several SaaS startups. Looking for a new in-person position with good benefits and work life balance.")
      user2.messages.create(role: "user", content: "I'm looking for a roommate to sign a new lease in Park Slope, Brooklyn.")
      user3.messages.create(role: "user", content: "I'm a founder at an early stage SaaS startup with a great product looking to bring on full stack web developers with 2-4 years SaaS experience who are available to work full time in person in NYC.")

      user1.search
      user2.search
      user3.search

      expect(user1.reload.matched_user).to eq(user3)
      expect(user1.status).to eq("matched")
      expect(user2.reload.status).to eq("searching")
      expect(user3.reload.status).to eq("matched")

      expect(user3.messages.last.role).to eq("assistant")
    end
  end
end
