require "rails_helper"

RSpec.describe Api::MessagesController, type: :request do
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

      allow(Telegram).to receive(:send_message)

      post api_messages_path(params)

      user = User.last
      expect(user.name).to eq("Eli Block")
      expect(user.telegram_username).to eq("eliblocks")
      expect(user.messages.count).to eq(2)
      expect(Message.last.role).to eq("assistant")

      expect(Telegram).to have_received(:send_message).with("5899443915", Prompts.welcome_message)
    end
  end
end
