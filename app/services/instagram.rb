class Instagram
  BASE_URL = "https://graph.instagram.com/v21.0"
  HEADERS = { "Content-Type" => "application/json" }

  class << self
    def http
      HTTP
        .auth("Bearer #{ENV["INSTAGRAM_ACCESS_TOKEN"]}")
        .headers({ "Content-Type" => "application/json" })
    end

    def profile(id)
      http.get("#{BASE_URL}/#{id}", params: { fields: "name,username" })
    end

    def send_message(id, text)
      http.post("#{BASE_URL}/#{ENV["INSTAGRAM_PROFILE_ID"]}/messages", json: {
        recipient: { id: },
        message: { text: }
      })
    end
  end
end
