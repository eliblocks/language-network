require "rails_helper"

RSpec.describe Api::MessagesController, type: :request do
  def message(params)
  end

  describe "#create" do
    it "creates a user and message" do
      params = {
        "update_id"=>460622228,
        "message"=> {
          "message_id"=>11,
          "from"=> {
            "id"=>5899443915,
            "is_bot" => false,
            "first_name" => "Eli",
            "last_name" => "Block",
            "username" => "eliblocks",
            "language_code" => "en"
          },
          "chat" => {
            "id"=>5899443915,
            "first_name"=>"Eli",
            "last_name"=>"Block",
            "username" => "eliblocks",
            "type"=>"private"
          },
          "date" => 1727550821,
          "text"=>"Hello"
        }
      }

      # client = instance_double(OpenAI::Client)
      # allow(OpenAI::Client).to(receive(:new)).and_return client
      # allow(client).to receive(:chat).and_return({ "choices" => [ { "message" => { "content" => "Yes" } } ] })
      allow(Net::HTTP).to receive(:post)

      post api_messages_path(params)

      user = User.last
      expect(user.name).to eq("Eli Block")
      expect(user.telegram_username).to eq("eliblocks")
      expect(user.messages.count).to eq(2)
      expect(Message.last.role).to eq("assistant")

      expect(Net::HTTP).to have_received(:post).with(
        a_kind_of(URI::HTTPS),
        { "text" => user.welcome_message, "chat_id" => "5899443915" }.to_json,
        a_kind_of(Hash)
      )
    end
  end
end
