class User < ActiveRecord::Base
  mount_uploader :picture, PictureUploader
  has_many :microposts, dependent: :destroy
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  has_many :followed_users, through: :relationships, source: :followed
  has_many :reverse_relationships, foreign_key: "followed_id",
           class_name:  "Relationship",
           dependent:   :destroy
  has_many :followers, through: :reverse_relationships, source: :follower
  before_save { self.email = email.downcase }
  validates :name, presence: true, length: { maximum: 50, minimum: 2}
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: {with: VALID_EMAIL_REGEX}, uniqueness: { case_sensitive: false }
  has_secure_password
  #VALID_PASSWORD_REGEX = /\A[A-Z]+[[a-zA-Z]+\d+]+[A-Z]+\z/
  validates :password, length: { minimum: 6 }

  before_create :create_remember_token

  def User.new_remember_token
    SecureRandom.urlsafe_base64
  end
  def User.encrypt(token)
    Digest::SHA1.hexdigest(token.to_s) # SHA1 faster than bcrypt
  end

  def feed
    Micropost.from_users_followed_by(self)
  end

  def following?(other_user)
    relationships.find_by(followed_id: other_user.id)
  end

  def follow!(other_user)
    relationships.create!(followed_id: other_user.id)
  end

  def unfollow!(other_user)
    relationships.find_by(followed_id: other_user.id).destroy
  end

  def save_and_process_picture(options = {})
    if options[:now]
      puts "He entrado a guardar desde el worker con el #{self.name} y #{self.id}"
      self.remote_picture_url = picture.direct_fog_url(:with_path => true)
      image = MiniMagick::Image.open(self.picture.current_path)
      image.resize "50x50"
      image.write "#{self.picture.current_path}"
      puts "Esta es la url remota #{self.remote_picture_url}"
      puts "Imagen #{self.picture}"
      #self.password = '123456789'
      #self.password_confirmation = '123456789'
      puts "Contraseña : #{self.password}"
      puts "Se intenta guardar"
      if save
        puts "Se ha guardado en S3"
      else
        puts "No se ha guardado"
      end
    else
      puts "He encolado desde el create"
      puts "He encolado desde el create con contraseña #{self.password}"
      Resque.enqueue(PictureProcessor, self.id, self.key, self.password)
      true
      puts "He salido de la cola desde el create"
    end
  end

  private # hidden from everyone except the User model
  def create_remember_token # 2
    self.remember_token = User.encrypt(User.new_remember_token) # self = the object being created
  end
end

