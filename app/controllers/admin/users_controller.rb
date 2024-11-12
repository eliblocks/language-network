class Admin::UsersController < AdminController
  def index
    @users = User.where(role: "user")
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def edit
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(user_params)
    @user.password = "password"
    @user.confirmed_at = Time.now
    @user.save!

    redirect_to admin_users_path
  end

  def update
    @user = User.find(params[:id])
    @user.assign_attributes(user_params)

    @user.telegram_id = nil unless @user.telegram_id.present?
    @user.telegram_username = nil unless @user.telegram_username.present?

    @user.save!

    redirect_to admin_users_path
  end

  def reset
    @user = User.find(params[:user_id])
    @user.messages.each(&:destroy!)
    Match.where(searching_user_id: @user.id).destroy_all
    Match.where(matched_user_id: @user.id).destroy_all
    @user.update!(status: "initial")

    redirect_to admin_users_path
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy

    redirect_to admin_users_path
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :telegram_id, :telegram_username, :role, :status).compact_blank
  end
end
