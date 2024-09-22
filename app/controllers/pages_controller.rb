class PagesController < ApplicationController
  def home
    redirect_to new_user_session_path unless user_signed_in?

    redirect_to admin_users_path if current_user&.admin?
  end
end
