class Admin::MessagesController < AdminController
  def create
    @user = User.find(params[:user_id])
    @user.messages.create!(role: "user", content: params[:message][:content])
    @user.respond

    redirect_to admin_user_path(@user)
  end

  def destroy
    @user = User.find(params[:user_id])
    @message = @user.messages.find(params[:id])
    @message.destroy

    redirect_to admin_user_path(@user)
  end
end
