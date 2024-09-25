class Admin::MessagesController < AdminController
  def create
    @user = User.find(params[:user_id])
    @user.messages.create!(message_params)
    @user.summarize

    redirect_to admin_user_path(@user)
  end

  def destroy
    @user = User.find(params[:user_id])
    @message = @user.messages.find(params[:id])
    @message.destroy

    redirect_to admin_user_path(@user)
  end

  private

  def message_params
    params.require(:message).permit(:content, :role)
  end
end
