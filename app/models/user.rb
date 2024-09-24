class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :messages, dependent: :destroy

  def admin?
    role == "admin"
  end

  def format_messages
    <<~HEREDOC
      USER CONVERSATION
      user id: #{id}
      user email: #{email}


      #{messages.format}
    HEREDOC
  end
end
