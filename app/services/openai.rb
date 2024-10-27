class Openai
  def chat(messages)
    Rails.logger.info "Messaging ChatGPT:"
    messages.each { |message| Rails.logger.info message }

    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4o-2024-08-06",
        messages:,
        temperature: 0.5
      }
    ).dig("choices", 0, "message", "content")

    Rails.logger.info "ChatGPT Response: #{response}"

    response
  end

  def embed(input)
    response = OpenAI::Client.new.embeddings(
      parameters: {
        model: "text-embedding-3-large",
        input: summary
      }
    )

    response.dig("data", 0, "embedding")
  end
end
