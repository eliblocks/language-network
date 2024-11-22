class Ai
  PROVIDER="openai"

  class << self
    def chat(messages, type)
      Rails.logger.info "Messaging ChatGPT:"
      messages.each { |message| Rails.logger.info message }

      response = (PROVIDER == "openai" ? openai_chat(messages, type) : anthropic_chat(messages))

      Rails.logger.info "Response: #{response}"

      response
    end

    def openai_chat(messages, type)
      messages.unshift({ role: "system", content: Prompts.system })

      OpenAI::Client.new.chat(
        parameters: {
          model: "gpt-4o-2024-08-06",
          messages:,
          temperature: 0.5,
          store: true,
          metadata: { type:, environment: Rails.env }
        },
      ).dig("choices", 0, "message", "content")
    end

    def anthropic_chat(messages)
      Anthropic::Client.new.messages(
        parameters: {
          model: "claude-3-5-sonnet-latest",
          system: Prompts.system,
          messages: messages
        },
      )
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
