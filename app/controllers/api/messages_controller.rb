class Api::MessagesController < ApiController
  def create
    from = params["message"]["from"]
    telegram_id = from["id"].to_s
    user = User.find_by(telegram_id: telegram_id) || User.create_from_telegram(from)
    user.messages.create(role: "user", content: params["message"]["text"])
    user.respond
  end
end
