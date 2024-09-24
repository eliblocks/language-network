class Message < ApplicationRecord
  belongs_to :user

  ROLES = [ "user", "assistant" ]

  validates :role, inclusion: { in: ROLES }

  def self.format
    all.map(&:to_s).join("\n\n")
  end

  def to_s
    <<~MESSAGE
      date: #{created_at.strftime("%Y-%m-%d %H:%M:%S")}
      role: #{role}
      content: #{content}
    MESSAGE
  end
end
