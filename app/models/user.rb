class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :messages, dependent: :destroy

  def platform_description
    <<~HEREDOC
      Language Network is a community platform that connects people with mutual requirements,
      for example people seeking roommates or jobs.
      Users must explain a little about themselves and what they are looking for,
      and then the platform will try to find a good match to suggest a connection
    HEREDOC
  end

  def welcome_prompt
    <<~HEREDOC
      You are welcoming a new user to Language Network.
      We are trying to get new users to post about what who they are and what they are looking for.
      Once we determine from the conversation that we have enough information to suggest a connection with another user
      we will let them know that we will look for matches.
    HEREDOC
  end

  def summary_prompt
    "Summarize the interest of the user with the following conversation:\n\n"
  end

  def admin?
    role == "admin"
  end

  def welcome_message
    "#{platform_description}\n\n#{welcome_prompt}\n\n#{format_messages}"
  end

  def welcome_response
    message = { role: 'system', content: welcome_message }
    chat(message).dig("choices", 0, "message", "content")
  end

  def welcome
    messages.create(role: 'assistant', content: welcome_response)
  end

  def format_messages
    <<~HEREDOC
      USER CONVERSATION
      user id: #{id}
      user email: #{email}


      #{messages.format}
    HEREDOC
  end

  def respond
    if messages.count == 1
      welcome
    else
      continue_conversation
    end
  end

  def continue_conversation
    messages.create(role: 'assistant', content: 'OK')
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
