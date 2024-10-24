class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :messages, dependent: :destroy

  validates :email, uniqueness: true
  validates :telegram_id, uniqueness: true, allow_nil: true
  validates :telegram_username, uniqueness: true, allow_nil: true

  has_neighbors :embedding

  User.attributes_for_inspect = [ :id, :email, :telegram_id, :telegram_username, :first_name, :last_name, :summary, :status, :role, :created_at, :updated_at ]

  SEARCH_SIZE = 100

  def platform_description
    <<~HEREDOC
      You are a bot that makes connections.
      People message you when they need something and whenever you feel you have enough information you let them know that you will be on the lookout for any users that can be of use to them.
      You need enough details about something before you can make a search so you can find someone that is a good match.

      However do not ask for exessive detail, if the user provides details in their first message dont ask for more unless needed.
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

  def fetch_active?
    response = chat_message("system", active_prompt)
    response.downcase == "active"
  end

  def active_prompt
    <<~HEREDOC
      #{platform_description}

      Based on the conversation below which status should we set the user to?

      active - We should be actively searching for matches.
      inactive - We should not be searching for matches at this moment.

      respond with only one word, active or inactive.

      #{formatted_messages}
    HEREDOC
  end

  def continue_conversation_prompt
    <<~HEREDOC
      #{platform_description}

      Guide the user towards providing sufficient information that could be used to match them with other users.
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

  def respond_with_chatbot(system_prompt)
    items = messages.as_json(only: [ :role, :content ])
    response = chat_messages(system_prompt, items)
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
      UpdateStatusJob.perform_later(id)
    end
  end

  def update_status
    if fetch_active?
      update(status: "searching")
    else
      update(status: "drafting")
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
    response = chat_message("system", summary_prompt)
    update!(summary: response)
  end

  def embed
    raise "Requires a summary" unless summary

    response = OpenAI::Client.new.embeddings(
      parameters: {
        model: "text-embedding-3-large",
        input: summary
      }
    )

    vector = response.dig("data", 0, "embedding")

    update!(embedding: vector)
  end

  def searchers
    User.where(status: "searching").where.not(id: id)
  end

  def closest_matches
    searchers.nearest_neighbors(:embedding, embedding, distance: "euclidean").first(SEARCH_SIZE)
  end

  def compare(user1, user2)
    raise "Users not in searching status" unless user1.searching? && user2.searching?

    response = chat_message("system", comparison_prompt(user1, user2))
    User.find(response)
  end

  def best_match
    raise "User not in searching status" unless searching?

    best = nil

    closest_matches.each do |user|
      best = (best ? compare(best, user) : user)
    end

    best
  end

  def good_match?(possible_match)
    response = chat_message("system", good_match_prompt(possible_match))
    response.downcase.include?("yes")
  end

  def search
    return unless searching?

    summarize
    embed
    best = best_match

    return unless best && good_match?(best)

    create_match(best)
  end

  def create_match(user)
    ActiveRecord::Base.transaction do
      Match.create(searching_user_id: id, matched_user_id: user.id)

      searcher_message = messages.create(role: "assistant", content: "I found someone you should meet! #{telegram_link || first_name}")
      matched_message = user.messages.create(role: "assistant", content: "I found someone you should meet! #{telegram_link || first_name}")

      send_telegram(searcher_message) if telegram_id
      user.send_telegram(matched_message) if user.telegram_id

      update(status: "matched")
      user.update(status: "matched")
    end
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

  def chat_message(role, content)
    chat([ { role:, content: } ])
  end

  def chat_messages(system, messages)
    chat(messages.unshift(role: "system", content: system))
  end

  def chat(messages)
    Rails.logger.info "Messaging ChatGPT: #{messages}"

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
end
