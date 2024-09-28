class Api::MessagesController < ApiController
  def create
    telegram_id = params["message"]["from"]["id"].to_s
    user = User.find_by(telegram_id: telegram_id) || User.create_from_telegram(telegram_id)
    user.messages.create(role: "user", content: params["message"]["text"])
    user.respond
  end
end
