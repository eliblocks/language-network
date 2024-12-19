class Discord
  BASE_URL = "https://discord.com/api/v10"

  class << self
    def http
      HTTP.headers({ "Content-Type" => "application/json", "Authorization" => "Bot #{ENV["DISCORD_TOKEN"]}" })
    end

    def send_message(recipient_id, content)
      channel = http.post("#{BASE_URL}/users/@me/channels", json: { recipient_id: })
      channel_id = JSON.parse(channel).dig("id")

      http.post("#{BASE_URL}/channels/#{channel_id}/messages", json: { recipient_id:, content: })
    end
  end
end
