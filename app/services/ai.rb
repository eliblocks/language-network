class Ai
  PROVIDER="openai"

  class << self
    def chat(messages, type: nil, format: nil)
      Rails.logger.info "Messaging ChatGPT:"
      messages.each { |message| Rails.logger.info message }

      response = (PROVIDER == "openai" ? openai_chat(messages, type:, format:) : anthropic_chat(messages))

      Rails.logger.info "Response: #{response}"

      response
    end

    def openai_chat(messages, type: nil, format: nil)
      messages.unshift({ role: "system", content: Prompts.system })

      OpenAI::Client.new.chat(
        parameters: {
          model: "gpt-4o-2024-08-06",
          messages:,
          response_format: format,
          temperature: 0.5,
          store: true,
          metadata: { type:, environment: Rails.env }
        },
      ).dig("choices", 0, "message", "content")
    end

    def anthropic_chat(messages, type: nil, format: nil)
      response = Anthropic::Client.new.messages(
        parameters: {
          model: "claude-3-5-sonnet-latest",
          max_tokens: 1024,
          system: Prompts.system,
          messages: messages
        },
      )

      response.dig("content", 0, "text")
    rescue => e
      Rails.logger.error(response)
      raise e
    end

    def embed(input)
      response = OpenAI::Client.new.embeddings(
        parameters: {
          model: "text-embedding-3-large",
          input:
        }
      )

      response.dig("data", 0, "embedding")
    end
  end
end
