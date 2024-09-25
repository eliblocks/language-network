class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :messages, dependent: :destroy

  def admin?
    role == "admin"
  end

  def summary_prompt
    "Summarize the interest of the user with the following conversation:\n\n"
  end

  def format_messages
    <<~HEREDOC
      USER CONVERSATION
      user id: #{id}
      user email: #{email}


      #{messages.format}
    HEREDOC
  end

  def summarize
    content = summary_prompt + format_messages
    message = { role: "system", content: }
    response = chat(message).dig("choices", 0, "message", "content")
    update!(search: response)
  end

  def chat(message)
    OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4o-2024-08-06",
        messages: [ message ],
        temperature: 0.5
      }
    )
  end
end
