class Api::WebhooksController < ApiController
  def verify_facebook
    render json: params["hub.challenge"]
  end

  def facebook
    head :ok
  end

  def verify_instagram
    render json: params["hub.challenge"]
  end

  def instagram
    messaging = params.dig("entry", 0, "messaging", 0)
    instagram_id = messaging.dig("sender", "id")
    text = messaging.dig("message", "text")

    return head :ok unless text
    return head :ok if instagram_id == ENV["INSTAGRAM_PROFILE_ID"]

    user = User.find_or_initialize_by(instagram_id:) do |user|
      user.email = "#{instagram_id}@example.com"
      user.password = SecureRandom.hex
    end

    profile = JSON.parse(Instagram.profile(instagram_id))
    user.instagram_username = profile["username"]
    names = profile["name"]&.split(" ")

    if names
      user.last_name = names.pop
      user.first_name = names.join(" ")
    end

    user.save!

    user.messages.create(role: "user", content: text)
    user.respond

    head :ok
  end
end
