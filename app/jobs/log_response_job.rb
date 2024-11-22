class LogResponseJob < ApplicationJob
  LATITUDE_BASE_URL = "https://gateway.latitude.so/v2/projects/10747/versions/704177f8-0258-4e88-acef-0d6efcf51184/documents"

  def perform(type, response)
    http = HTTP
            .auth("Bearer #{ENV["LATITUDE_TOKEN"]}")
            .headers({ "Content-Type" => "application/json" })

    http.post("#{LATITUDE_BASE_URL}/getOrCreate", json: { path: type })
    http.post("#{LATITUDE_BASE_URL}/logs", json: response)
  end
end
