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
    <<~HEREDOC
      Hello! I'm a bot that can connect you to people based on your needs. Tell me a little about what you're looking for and I'll try to find someone relevant to you.
    HEREDOC
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
      user first name: #{first_name}


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
    response = system_message(active_prompt)
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

  def introduction_prompt
    <<~HEREDOC
      We are trying to craft a text message to introduce two users based on their conversations below.
      We need to return the actual message, not an explanation of the message, because the result of this prompt will be sent to the user on the Telegram app.
      This message will be sent to the user in middle of their current conversation so no need for a greeting.
      Also, we need to include a telegram link so the user can message their match.

      We are sending a message to #{first_name} to let him know about #{matched_user.first_name}. #{matched_user.first_name}'s Telegram Link is #{matched_user.telegram_link}


      #{formatted_messages}


      #{matched_user.formatted_messages}
    HEREDOC
  end

  def introduction
    raise "User not in matched status" unless status == "matched"

    system_message(introduction_prompt)
  end

  def searching?
    status == "searching"
  end

  def chat_completion(prompt)
    items = [ { role: "system", content: prompt } ]
    items.concat(messages.as_json(only: [ :role, :content ]))
    Ai.chat(items)
  end

  def respond_with_chatbot(prompt)
    response = chat_completion(prompt)
    message = messages.create(role: "assistant", content: response)

    send_telegram(message) if telegram_id
  end

  def respond
    if messages.count == 1
      message = messages.create(role: "assistant", content: welcome_message)
      send_telegram(message)
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

    Telegram.send_message(telegram_id, message.content)
  end

  def summarize
    response = system_message(summary_prompt)
    update!(summary: response)
  end

  def embed
    raise "Requires a summary" unless summary

    update!(embedding: Ai.embed(summary))
  end

  def searchers
    User.where(status: "searching").where.not(id: id)
  end

  def closest_matches
    searchers.nearest_neighbors(:embedding, embedding, distance: "euclidean").first(SEARCH_SIZE)
  end

  def compare(user1, user2)
    raise "Users not in searching status" unless user1.searching? && user2.searching?

    response = system_message(comparison_prompt(user1, user2))
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
    response = system_message(good_match_prompt(possible_match))
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

      update(status: "matched")
      user.update(status: "matched")
    end

    respond_with_chatbot(introduction_prompt)
    user.respond_with_chatbot(user.introduction_prompt)
  end

  def telegram_link
   "<a href='tg://user?id=#{telegram_id}'>#{name}</a>"
  end

  def matched_user
    match = Match.where(status: "active").where("searching_user_id = ? or matched_user_id = ?", id, id)&.last

    return unless match

    match.searching_user == self ? match.matched_user : match.searching_user
  end

  def system_message(content)
    Ai.chat([ { role: "system", content: } ])
  end
end
