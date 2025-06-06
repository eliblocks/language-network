class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :messages, dependent: :destroy

  validates :email, uniqueness: true
  validates :telegram_id, uniqueness: true, allow_nil: true
  validates :telegram_username, uniqueness: true, allow_nil: true

  validates :instagram_id, uniqueness: true, allow_nil: true
  validates :instagram_username, uniqueness: true, allow_nil: true

  has_neighbors :embedding

  User.attributes_for_inspect = [ :id, :email, :telegram_id, :telegram_username, :instagram_id, :instagram_username, :first_name, :last_name, :summary, :status, :role, :created_at, :updated_at ]

  SEARCH_SIZE = 100

  def prompts
    Prompts.new(self)
  end

  def formatted_messages
    <<~HEREDOC
      USER CONVERSATION
      user id: #{id}
      user first name: #{first_name}


      #{messages.order(:created_at).format}
    HEREDOC
  end

  def username
    telegram_username || instagram_username || discord_username || email
  end

  def intro_name
    first_name || instagram_username
  end

  def name
    return "" unless first_name
    return first_name unless last_name

    "#{first_name} #{last_name}"
  end

  def admin?
    role == "admin"
  end

  def respond
    if messages.count == 1 && messages.last.content.length < 30
      message = messages.create(role: "assistant", content: Prompts.welcome_message)
      update(status: "drafting")
      send_message(message)
    else
      respond_with_chatbot
      UpdateStatusJob.perform_later(id)
    end
  end

  def update_status
    new_status = JSON.parse(fetch_status)["status"]

    if new_status == "active"
      update(status: "searching")
    elsif new_status == "inactive"
      update(status: "drafting")
    else
      raise "AI returned invalid status"
    end
  end

  def search
    return unless searching?

    summarize
    embed
    best = best_match

    return unless best && good_match?(best)

    create_match(best)
  end

  def matched_user
    match = Match.where(status: "active").where("searching_user_id = ? or matched_user_id = ?", id, id)&.last

    return unless match

    match.searching_user == self ? match.matched_user : match.searching_user
  end

  def service
    if telegram_id?
      "Telegram"
    elsif instagram_id?
      "Instagram"
    elsif discord_id?
      "Discord"
    else
      "Web"
    end
  end

  def searching?
    status == "searching"
  end

  def profile_link
    telegram_id ? telegram_link : instagram_link
  end

  def introduce(user)
    prompt = prompts.introduction(user)
    response = system_message(prompt, type: "introduction")
    response += " #{user.profile_link}" if user.instagram_id

    message = messages.create(role: "assistant", content: response)

    send_message(message)
  end

  # private

  def telegram_link
  "<a href='tg://user?id=#{telegram_id}'>#{name}</a>"
  end

  def instagram_link
    "https://www.instagram.com/#{instagram_username}"
  end

  def respond_with_chatbot
    message = messages.create(role: "assistant", content: chat_completion)

    send_message(message)
  end

  def fetch_status
    system_message(prompts.status, type: "status", format: Prompts.status_format).downcase
  end

  def send_message(message)
    if telegram_id
      send_telegram(message)
    elsif instagram_id
      send_instagram(message)
    elsif discord_id
      send_discord(message)
    end
  end

  def send_telegram(message)
    return unless telegram_id

    Telegram.send_message(telegram_id, message.content)
  end

  def send_instagram(message)
    return unless instagram_id

    Instagram.send_message(instagram_id, message.content)
  end

  def send_discord(message)
    return unless discord_id

    Discord.send_message(discord_id, message.content)
  end

  def embed
    raise "Requires a summary" unless summary

    update!(embedding: Ai.embed(summary))
  end

  def searchers
    collection = User.where(status: "searching").where.not(id: id)
    if telegram_id
      collection = collection.where.not(telegram_id: nil)
    elsif instagram_id
      collection = collection.where.not(instagram_id: nil)
    elsif discord_id
      collection = collection.where.not(discord_id: nil)
    else
      collection = collection.where(telegram_id: nil, instagram_id: nil, discord_id: nil)
    end

    collection
  end

  def closest_matches
    searchers.nearest_neighbors(:embedding, embedding, distance: "euclidean").first(SEARCH_SIZE)
  end

  def best_match
    raise "User not in searching status" unless searching?

    best = nil

    closest_matches.each do |user|
      best = (best ? compare(best, user) : user)
    end

    best
  end

  def compare(user1, user2)
    raise "users are same" if user1 == user2
    raise "Users not in searching status" unless user1.searching? && user2.searching?

    response = system_message(prompts.comparison(user1, user2), type: "comparison", format: Prompts.comparison_format)
    best_id = JSON.parse(response)["user_id"]

    User.find(best_id)
  end

  def summarize
    response = system_message(prompts.summary, type: "summarization")
    update!(summary: response)
  end

  def good_match?(possible_match)
    response = system_message(prompts.good_match(possible_match), type: "match")
    response.downcase.include?("yes")
  end

  def create_match(user)
    ActiveRecord::Base.transaction do
      Match.create(searching_user_id: id, matched_user_id: user.id)

      update(status: "matched")
      user.update(status: "matched")
    end

    introduce(user)
    user.introduce(self)
  end

  def system_message(content, type: nil, format: nil)
    Ai.chat([ { role: "user", content: } ], type:, format:)
  end

  def chat_completion
    Ai.chat(messages.order(:created_at).as_json(only: [ :role, :content ]), type: "conversation")
  end
end
