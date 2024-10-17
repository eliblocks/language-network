class Admin::UsersController < AdminController
  def index
    @users = User.all
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
    @user.update!(user_params)

    redirect_to admin_users_path
  end

  def reset
    @user = User.find(params[:user_id])
    @user.messages.each(&:destroy!)
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
    params.require(:user).permit(:email, :first_name, :last_name, :telegram_id, :telegram_username, :role, :status)
  end
end
