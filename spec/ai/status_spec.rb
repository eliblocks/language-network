require "rails_helper"

RSpec.describe "Status", :vcr, type: :model do
  it "does not set incomplete running example to searching status" do
    messages = [
      { role: "user", content: "Hello" },
      { role: "assistant", content: "Hello! I'm a bot that can connect you to people. Tell me a little about what you're looking for and I'll try to find someone relevant to you." },
      { role: "user", content: "I'm looking to go for a running partner in NYC on the west side highway" },
      { role: "assistant", content: "Great! How often do you plan on running, and what pace or distance are you comfortable with? This will help me find someone who matches your running style." }
    ]
    messages.map! { |attrs| Message.new(attrs) }
    user = create(:user)
    user.messages << messages
    10.times do
      user.update_status
      expect(user.status).to eq("drafting")
    end
  end

  it "does not set incomplete pickleball example to searching status" do
    messages = [
      { role: "user", content: "Hello" },
      { role: "assistant", content: "Hello! I'm a bot that can connect you to people. Tell me a little about what you're looking for and I'll try to find someone relevant to you." },
      { role: "user", content: "I'm looking for a pickleball partner" },
      { role: "assistant", content: "Got it! Could you tell me your skill level and when you're usually available to play? This will help me find a compatible pickleball partner for you." }
    ]
    messages.map! { |attrs| Message.new(attrs) }
    user = create(:user)
    user.messages << messages
    10.times do
      user.update_status
      expect(user.status).to eq("drafting")
    end
  end

  it "sets complete job search example to searching status" do
    messages = [
      { role: "user", content: "Hello" },
      { role: "assistant", content: "Hello! I'm a bot that can connect you to people. Tell me a little about what you're looking for and I'll try to find someone relevant to you." },
      { role: "user", content: "I'm a software engineer in NYC with experience using Ruby on Rails at several SaaS startups. Looking for a new in-person position with good benefits and work life balance." },
      { role: "assistant", content: "Great! I'll let you know if I find someone looking for an engineer with your skills." }
    ]
    messages.map! { |attrs| Message.new(attrs) }
    user = create(:user)
    user.messages << messages
    10.times do
      user.update_status
      expect(user.status).to eq("searching")
    end
  end
end
