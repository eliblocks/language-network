require "rails_helper"

# rubocop:disable all
RSpec.describe "GoodMatch", :vcr, type: :model do
  it "returns yes for good matches" do
    eli = create(:user, first_name: "Eli")
    messages = [{:role=>"user", :content=>"Hello"},
    {:role=>"assistant", :content=>"Hello! I'm a bot that can connect you to people. Tell me a little about yourself and what you're looking for and I'll try to find someone relevant to you.\n"},
    {:role=>"user", :content=>"I’m an intermediate volleyball player and new to NYC, just heard about a tournament and I need to find a doubles partner at my level! All my friends are too advanced"},
    {:role=>"assistant",
      :content=>
      "Got it, you're an intermediate volleyball player in NYC looking for a doubles partner at a similar skill level for an upcoming tournament. I'll be on the lookout for anyone who fits that description. If there's anything else I should know, feel free to share!"},
    {:role=>"assistant",
      :content=>
      "Eli is an intermediate volleyball player in NYC looking for a doubles partner at a similar skill level for an upcoming tournament. They’re new to the city and might also be interested in connecting with others for sports. https://www.instagram.com/eliblockdevelopment"},
    {:role=>"user", :content=>"Hi"},
    {:role=>"assistant", :content=>"Hi there! I'm a bot that helps connect people. Let me know what you're looking for or need help with, and I'll try to find someone who can help or match with you!"},
    {:role=>"user", :content=>"I’m looking to meet people for pickup basketball in NYC"},
    {:role=>"assistant", :content=>"Got it! You're looking to meet people for pickup basketball games in NYC. I'll keep an eye out for anyone interested in that. Let me know if there's anything specific you'd like me to know, like your skill level or preferred locations!"},
    {:role=>"user", :content=>"All levels"},
    {:role=>"assistant", :content=>"Great, you're open to playing basketball with people of all skill levels in NYC. I'll be on the lookout for anyone interested in pickup games. Let me know if you have any other details to add!"}]

    messages.each { |attrs| eli.messages.create!(attrs) }


    mus = create(:user, first_name: "Musti")

    [{:role=>"user", :content=>"Hey"},
    {:role=>"assistant", :content=>"Hello! I'm a bot that can connect you to people. Tell me a little about yourself and what you're looking for and I'll try to find someone relevant to you.\n"},
    {:role=>"user", :content=>"I am Musti in New York"},
    {:role=>"assistant", :content=>"Nice to meet you, Musti! What can I help you with? Are you looking to connect with someone for work, hobbies, advice, or something else? Let me know and I'll do my best to assist."},
    {:role=>"user", :content=>"I want to connect to some other people who play basketball here"},
    {:role=>"assistant", :content=>"Got it, Musti! You're looking to connect with others in New York who play basketball. Are you looking for casual pick-up games, joining a team, or just meeting other basketball enthusiasts? The more I know, the better I can help!"},
    {:role=>"user", :content=>"Pick up"},
    {:role=>"assistant", :content=>"Great! I'll be on the lookout for anyone else in New York interested in pick-up basketball games. Let me know if there's anything else you'd like me to consider while I search!"}]
    
    mus = create(:user, first_name: "Musti")

    messages.each { |attrs| mus.messages.create!(attrs) }

    expect(eli.good_match?(mus)).to eq(true)
    expect(mus.good_match?(eli)).to eq(true)
  end
end

# rubocop:enable all
