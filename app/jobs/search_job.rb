class SearchJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    return unless user.searching?

    user.seek
  end
end
