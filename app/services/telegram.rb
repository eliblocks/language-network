class Telegram
  BASE_URL = "https://api.telegram.org/bot#{ENV.fetch("TELEGRAM_TOKEN")}"
  HEADERS = { "Content-Type" => "application/json" }

  class << self
    def post(path, body)
      Net::HTTP.post(URI(BASE_URL + path), body, HEADERS)
    end

    def send_message(chat_id, text)
      post("/sendMessage", { chat_id:, text:, parse_mode: "HTML" }.to_json)
    end
  end
end
