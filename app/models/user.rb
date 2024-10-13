class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :messages, dependent: :destroy

  def self.create_from_telegram(params)
    telegram_id = params["id"].to_s
    first_name = params["first_name"]
    last_name = params["last_name"]
    email = "#{telegram_id}@example.com"
    password = SecureRandom.hex

    create!(email:, password:, telegram_id:, first_name:, last_name:)
  end

  def platform_description
    <<~HEREDOC
      Language Network is a community platform that connects people with mutual requirements,
      for example people seeking roommates or jobs.
      Users must explain a little about themselves and what they are looking for,
      and then the platform will try to find a good match to suggest a connection
    HEREDOC
  end

  def welcome_instructions
    <<~HEREDOC
      You are welcoming a new user to Language Network.
      We are trying to get new users to post about what who they are and what they are looking for.
      Once we determine from the conversation that we have enough information to suggest a connection with another user
      we will let them know that we will look for matches.
    HEREDOC
  end

  def comparison_instructions
    <<~HEREDOC
      We are now trying to find the best match for the searching user. 
      Given the user and two other users along with their conversation histores,
      return the user id of the best match for the searching user
    HEREDOC
  end

  def formatted_messages
    <<~HEREDOC
      USER CONVERSATION
      user id: #{id}
      user email: #{email}
      user full name: #{name}


      #{messages.format}
    HEREDOC
  end

  def summary_prompt
    "Summarize the interest of the user with the following conversation:\n\n#{formatted_messages}"
  end

  def comparison_prompt(user1, user2)
    <<~HEREDOC
      #{platform_description}

      #{comparison instructions}

      searching user
      #{formatted_messages}

      possible match
      #{user1.formatted_messages}

      possible match
      #{user2.formatted_messages}
    HEREDOC
  end

  def name
    return "" unless first_name
    return first_name unless last_name

    "#{first_name} #{last_name}"
  end

  def admin?
    role == "admin"
  end

  def welcome_prompt
    "#{platform_description}\n\n#{welcome_instructions}\n\n#{formatted_messages}"
  end

  def welcome_response
    chat("system", welcome_prompt)
  end

  def post_complete?
    response = chat("system", is_post_complete_prompt)
    response.downcase.include?("yes")
  end

  def is_post_complete_prompt
    <<~HEREDOC
      #{platform_description}

      Based the conversation with the user below, do we have enough information to generate a psot that can be matched against other users? Yes or No

      #{formatted_messages}
    HEREDOC
  end

  def create_post_prompt
    <<~HEREDOC
      #{platform_description}

      Based on the existing conversation below, guide the user towards providing sufficient information that could be used to match them with other users.

      #{formatted_messages}
    HEREDOC
  end

  def confirm_post_prompt
      <<~HEREDOC
      #{platform_description}

      We have determined that we collected sufficient information to begin matching this user.
      We will now search for anyone we can connect them too.
      Inform the user based on the existing conversation below.

      #{formatted_messages}
    HEREDOC
  end

  def respond_with_chatbot(content)
    response = chat("system", content)
    message = messages.create(role: "assistant", content: response)

    send_telegram(message) if telegram_id
  end

  def respond
    if post_complete?
      update(status: "searching")
      respond_with_chatbot(confirm_post_prompt)
    else
      respond_with_chatbot(create_post_prompt)
    end
  end

  def send_telegram(message)
    return unless telegram_id

    token = ENV.fetch("TELEGRAM_TOKEN")

    url = "https://api.telegram.org/bot#{token}/sendMessage"

    Net::HTTP.post(
      URI(url),
      { "text" => message.content, "chat_id" => telegram_id }.to_json,
      "Content-Type" => "application/json"
    )
  end

  def summarize
    response = chat("system", summary_prompt)
    update!(search: response)
  end

  def compare(user1, user2)
    response = chat("system", comparison_prompt)
    User.find(reponse)
  end

  def best_match
    best = nil
    User.where.not(id:).each do |user|
      best = user unless best

      best = compare(best, user)
    end

    best
  end

  def chat(role, content)
    OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4o-2024-08-06",
        messages: [ { role:, content: } ],
        temperature: 0.5
      }
    ).dig("choices", 0, "message", "content")
  end
end
