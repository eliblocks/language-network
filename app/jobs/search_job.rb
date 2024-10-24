class SearchJob < ApplicationJob
  def perform(user_id)
    User.find(user_id).search
  end
end
