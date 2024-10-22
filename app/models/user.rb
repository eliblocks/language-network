class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :messages, dependent: :destroy

  validates :email, uniqueness: true
  validates :telegram_id, uniqueness: true, allow_nil: true
  validates :telegram_username, uniqueness: true, allow_nil: true

  def platform_description
    <<~HEREDOC
      You are a bot that makes connections.
      People message you when they need something and whenever you feel you have enough information you let them know that you will be on the lookout for any users that can be of use to them.
      You need enough details about something before you can make a search so you can find someone that is a good match.
    HEREDOC
  end

  def welcome_message
    message = <<~HEREDOC
      Hello! I'm a bot that can connect you to people based on your needs. Tell me a little about what you're looking for and I'll try to find someone relevant to you.
    HEREDOC

    if telegram_id && !telegram_username
      message << "\n#{username_notice}"
    end

    message
  end

  def username_notice
    "Looks like you don't have a username set in Telegram. I'll need that to recommend you to other users."
  end

  def comparison_instructions
    <<~HEREDOC
      We are now trying to find the best match for the searching user.
      Given the user and two other users along with their conversation histores,
      return the user id of the best match for the searching user. return only a user_id.
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

      #{comparison_instructions}

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

  def ready_to_search?
    response = chat("system", ready_to_search_prompt)
    response.downcase.include?("yes")
  end

  def ready_to_search_prompt
    <<~HEREDOC
      #{platform_description}

      Based on the conversation below, are we ready to search for matches? yes or no.

      #{formatted_messages}
    HEREDOC
  end

  def continue_conversation_prompt
    <<~HEREDOC
      #{platform_description}

      Based on the existing conversation below, guide the user towards providing sufficient information that could be used to match them with other users.

      #{formatted_messages}
    HEREDOC
  end

  def good_match_prompt(possible_match)
    <<~HEREDOC
      #{platform_description}

      Based on the conversations with two separate users below, are they a good match for each other? Return yes or no.

      #{formatted_messages}

      #{possible_match.formatted_messages}
    HEREDOC
  end

  def searching?
    status == "searching"
  end

  def respond_with_chatbot(content)
    response = chat("system", content)
    message = messages.create(role: "assistant", content: response)

    send_telegram(message) if telegram_id
  end

  def respond
    if messages.count == 1
      message = messages.create(role: "assistant", content: welcome_message)
      send_telegram(message)
    elsif telegram_id && !telegram_username
      message = messages.create(role: "assistant", content: username_notice)
    else
      respond_with_chatbot(continue_conversation_prompt)
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

  def searchers
    User.where(status: "searching").where.not(id: id)
  end

  def compare(user1, user2)
    raise "Users not in searching status" unless user1.searching? && user2.searching?

    response = chat("system", comparison_prompt(user1, user2))
    User.find(response)
  end

  def best_match
    raise "User not in searching status" unless searching?

    best = nil

    searchers.each do |user|
      best = (best ? compare(best, user) : user)
    end

    best
  end

  def good_match?(possible_match)
    response = chat("system", good_match_prompt(possible_match))
    response.downcase.include?("yes")
  end

  def seek
    best = best_match

    return unless best && good_match?(best)

    create_match(best)
  end

  def create_match(user)
    ActiveRecord::Base.transaction do
      Match.create(searching_user_id: id, matched_user_id: user.id)
      update(status: "matched")
      user.update(status: "matched")
    end
    introduce_to(user)
  end

  def introduce_to(user)
    message = user.messages.create(role: "assistant", content: "You should meet #{telegram_link || first_name}")
    user.send_telegram(message) if user.telegram_id
  end

  def telegram_link
    return nil unless telegram_username

    "https://t.me/#{telegram_username}"
  end

  def matched_user
    match = Match.where(status: "active").where("searching_user_id = ? or matched_user_id = ?", id, id)&.last

    return unless match

    match.searching_user == self ? match.matched_user : match.searching_user
  end

  def chat(role, content)
    Rails.logger.info "Messaging ChatGPT: #{content}"

    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4o-2024-08-06",
        messages: [ { role:, content: } ],
        temperature: 0.5
      }
    ).dig("choices", 0, "message", "content")

    Rails.logger.info "ChatGPT Response: #{response}"

    response
  end
end
