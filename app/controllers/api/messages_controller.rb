class Api::MessagesController < ApiController
  def create
    from = params["message"]["from"]
    telegram_id = from["id"].to_s
    telegram_username = from["username"]
    first_name = from["first_name"]
    last_name = from["last_name"]

    user = User.find_or_initialize_by(telegram_id:) do |user|
      user.email = "#{telegram_id}@example.com"
      user.password = SecureRandom.hex
    end
    user.assign_attributes(first_name:, last_name:, telegram_username:)
    user.save!

    user.messages.create(role: "user", content: params["message"]["text"])
    user.respond
  end
end
