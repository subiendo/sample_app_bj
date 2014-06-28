class PicturesController < ApplicationController
  def new
    @uploader = User.new.picture
    @uploader.success_action_redirect = new_user_url
  end
  def edit
    @user = User.find(params[:id])
    @uploader = User.new.picture
    @uploader.success_action_redirect = edit_user_url(@user)
  end
end