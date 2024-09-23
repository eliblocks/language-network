class Message < ApplicationRecord
  belongs_to :user

  ROLES = [ "user", "assistant" ]

  validates :role, inclusion: { in: ROLES }
end
