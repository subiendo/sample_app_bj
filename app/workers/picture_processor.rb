class PictureProcessor

  @queue = :picture_processor_queue

  def self.perform(user_id, picture_key, password)
    user = User.find(user_id)
    user.key = picture_key
    user.password = password
    user.password_confirmation = password
    user.save_and_process_picture(:now => true)
  end
end