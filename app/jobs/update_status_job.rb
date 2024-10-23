class UpdateStatusJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    user.update_status

    if user.reload.searching?
      SearchJob.perform_later(user_id)
    end
  end
end
