require "rails_helper"

RSpec.describe "Messaging", type: :request do
  def params(user, text)
    {
      "message" => {
        "from" => {
          "id" => user.telegram_id,
          "first_name" => user.first_name,
          "last_name" => user.last_name,
          "username" => user.telegram_username
        },
        "text" => text
      }
    }
  end

  it "handles messages", :vcr do
    allow(Net::HTTP).to receive(:post)

    # Sam initiates and searches
    sam = create(:telegram_user, first_name: "sam")
    expect(sam.status).to eq("initial")

    post api_messages_path(params(sam, "Hello"))
    expect(sam.messages.count).to eq(2)
    expect(sam.reload.status).to eq("drafting")

    sam_message = "I'm a software engineer in NYC with experience using Ruby on Rails at several SaaS startups. Looking for a new in-person position with good benefits and work life balance."
    post api_messages_path(params(sam, sam_message))

    expect(sam.reload.messages.count).to eq(4)
    expect(sam.reload.status).to eq("searching")

    # Bob initiates
    bob = create(:telegram_user, first_name: "bob")
    expect(bob.status).to eq("initial")

    post api_messages_path(params(bob, "Hello"))
    expect(bob.reload.messages.count).to eq(2)
    expect(bob.reload.status).to eq("drafting")

    # Bob searches and matches with Sam
    bob_message = "I'm a founder at an early stage SaaS startup with a great product looking to bring on full stack web developers with 2-4 years SaaS experience who are available to work full time in person in NYC."
    post api_messages_path(params(bob, bob_message))
    expect(sam.reload.messages.last.content).to include("<a href=")
    expect(sam.reload.status).to eq("matched")
    expect(bob.reload.messages.last.content).to include("<a href=")
    expect(bob.reload.status).to eq("matched")
    expect(sam.reload.matched_user).to eq(bob)

    # Sam and Bob no longer active
    post api_messages_path(params(sam, "Thank you"))
    expect(sam.reload.status).to eq("drafting")

    post api_messages_path(params(bob, "Thank you"))
    expect(bob.reload.status).to eq("drafting")

    # Sam reactivates

    post api_messages_path(params(sam, "Hello"))
    post api_messages_path(params(sam, "I'm looking to meet fellow intermediate basketball players in nyc for pickup"))
    expect(sam.reload.status).to eq("searching")

    # Max searches and Sam Rematches
    max = create(:telegram_user, first_name: "Max")
    post api_messages_path(params(max, "Hello"))
    post api_messages_path(params(max, "Im visiting new york, staying in manhattan and want to play pickup basketball as a way to meet locals! Open to all levels"))

    expect(max.reload.status).to eq("matched")
    expect(sam.reload.status).to eq("matched")
    expect(max.matched_user).to eq(sam)

    # Joe Searches
    joe = create(:telegram_user, first_name: "Joe")
    post api_messages_path(params(joe, "Hello"))
    post api_messages_path(params(joe, "I'm looking for people to go on hikes with. Im in nyc and usually take the train upstate to nearby trails. Im in pretty good hiking shape and looking for at least intermediate hikers"))
    expect(joe.reload.status).to eq("searching")

    # Sam searches again
    post api_messages_path(params(sam, "I live in NYC and trying to get out of the city for some strenous outdoor activites. Need people to explore with! I dont have a car but hopefully Ill figure something out."))
    expect(sam.reload.status).to eq("matched")
    expect(joe.reload.status).to eq("matched")
    expect(joe.matched_user).to eq(sam)
  end

  context "with instagram" do
    def params(user, text)
      {
        "object" => "instagram",
        "entry" => [
          {
            "time" => 1731261732963,
            "id" => ENV["INSTAGRAM_PROFILE_ID"],
            "messaging" => [
              {
                "sender" => {
                  "id" => user.instagram_id
                }, "recipient" => {
                  "id" => ENV["INSTAGRAM_PROFILE_ID"]
                },
                "timestamp" => 1731261730927,
                "message" => {
                  "text" => text
                }
              }
            ]
          }
        ]
      }
    end

    it "handles messages", :vcr do
      allow(Instagram).to receive(:send_message)

      # Mock the behavior of the Instagram.profile method
      allow(Instagram).to receive(:profile) do |id|
        user = User.find_by(instagram_id: id)
        { profile: { username: user&.instagram_username } }.to_json
      end

      # Sam initiates and searches
      sam = create(:instagram_user, first_name: "sam")
      expect(sam.status).to eq("initial")

      post api_webhooks_instagram_path(params(sam, "Hello"))
      expect(sam.messages.count).to eq(2)
      expect(sam.reload.status).to eq("drafting")

      sam_message = "I'm a software engineer in NYC with experience using Ruby on Rails at several SaaS startups. Looking for a new in-person position with good benefits and work life balance."
      post api_webhooks_instagram_path(params(sam, sam_message))

      expect(sam.reload.messages.count).to eq(4)
      expect(sam.reload.status).to eq("searching")

      # Bob initiates
      bob = create(:instagram_user, first_name: "bob")
      expect(bob.status).to eq("initial")

      post api_webhooks_instagram_path(params(bob, "Hello"))
      expect(bob.reload.messages.count).to eq(2)
      expect(bob.reload.status).to eq("drafting")

      # Bob searches and matches with Sam
      bob_message = "I'm a founder at an early stage SaaS startup with a great product looking to bring on full stack web developers with 2-4 years SaaS experience who are available to work full time in person in NYC."
      post api_webhooks_instagram_path(params(bob, bob_message))

      expect(sam.reload.messages.last.content).to include("www.instagram.com")
      expect(sam.reload.status).to eq("matched")
      expect(bob.reload.messages.last.content).to include("www.instagram.com")
      expect(bob.reload.status).to eq("matched")
      expect(sam.reload.matched_user).to eq(bob)
    end
  end
end
