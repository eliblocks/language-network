require "rails_helper"

RSpec.describe "Status", :vcr, type: :model do
  context "incomplete running example" do
    before(:each) do
      messages = [
        { role: "user", content: "Hello" },
        { role: "assistant", content: "Hello! I'm a bot that can connect you to people. Tell me a little about what you're looking for and I'll try to find someone relevant to you." },
        { role: "user", content: "I'm looking to go for a running partner in NYC on the west side highway" },
        { role: "assistant", content: "Great! How often do you plan on running, and what pace or distance are you comfortable with? This will help me find someone who matches your running style." }
      ]

      @user = create(:user)
      messages.map! { |attrs| Message.new(attrs) }
      @user.messages << messages
    end
    10.times do |i|
      it "updates user status correctly ##{i + 1}" do
        @user.update_status
        expect(@user.status).to eq("drafting")
      end
    end
  end

  context "incomplete pickleball example" do
    before(:each) do
      messages = [
        { role: "user", content: "Hello" },
        { role: "assistant", content: "Hello! I'm a bot that can connect you to people. Tell me a little about what you're looking for and I'll try to find someone relevant to you." },
        { role: "user", content: "I'm looking for a pickleball partner" },
        { role: "assistant", content: "Got it! Could you tell me your skill level and when you're usually available to play? This will help me find a compatible pickleball partner for you." }
      ]
      messages.map! { |attrs| Message.new(attrs) }
      @user = create(:user)
      @user.messages << messages
    end
    10.times do |i|
      it "is still in draft status ##{i + 1}" do
        @user.update_status
        expect(@user.status).to eq("drafting")
      end
    end
  end

  context "complete job search example" do
    before(:each) do
      messages = [
        { role: "user", content: "Hello" },
        { role: "assistant", content: "Hello! I'm a bot that can connect you to people. Tell me a little about what you're looking for and I'll try to find someone relevant to you." },
        { role: "user", content: "I'm a software engineer in NYC with experience using Ruby on Rails at several SaaS startups. Looking for a new in-person position with good benefits and work life balance." },
        { role: "assistant", content: "Great! I'll let you know if I find someone looking for an engineer with your skills." }
      ]
      messages.map! { |attrs| Message.new(attrs) }
      @user = create(:user)
      @user.messages << messages
    end
    10.times do |i|
      it "sets user to searching ##{i + 1}" do
        @user.update_status
        expect(@user.status).to eq("searching")
      end
    end
  end

  context "After match example" do
    before(:each) do
      messages = [
        { role: "user", content: "Hello" },
        { role: "assistant", content: "Hello! I'm a bot that can connect you to people. Tell me a little about what you're looking for and I'll try to find someone relevant to you." },
        { role: "user", content: "I'm a software engineer in NYC with experience using Ruby on Rails at several SaaS startups. Looking for a new in-person position with good benefits and work life balance." },
        { role: "assistant", content: "Great! I'll let you know if I find someone looking for an engineer with your skills." },
        { role: "assistant", content: "I have found a potential connection for you. Bob is a founder at an early stage SaaS startup in NYC looking to bring on full stack web developers with 2-4 years of SaaS experience for full-time in-person work. This opportunity might align well with your background and career goals. https://www.instagram.com." },
        { role: "user", content: "Thank you, that sounds like a great fit!" }
      ]
      messages.map! { |attrs| Message.new(attrs) }
      @user = create(:user)
      @user.messages << messages
    end
    10.times do |i|
      it "sets user back to drafting ##{i + 1}" do
        @user.update_status
        expect(@user.status).to eq("drafting")
      end
    end
  end
end
