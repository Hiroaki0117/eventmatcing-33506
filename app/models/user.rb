class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: [:facebook, :google_oauth2]
  with_options presence: true do
    validates :nickname
    validates :phone_number, format: { with: /\A\d{10,11}\z/, message: "は半角数字を入力してください" }
    validates :birth_day
    validates :area_id, numericality: { other_than: 1, message: "を選択してください" }
  end
  VALID_PASSWORD_REGEX = /\A(?=.*?[a-z])(?=.*?[\d])[a-z\d]+\z/i
  validates :password, format: { with: VALID_PASSWORD_REGEX, message: 'は英数字混合にしてください' }
  VALID_NAME_REGEX = /\A[ぁ-んァ-ヶ一-龥々]+\z/
  with_options presence: true, format: { with: VALID_NAME_REGEX, message: 'は全角文字で入力してください' } do
    validates :family_name
    validates :first_name
  end
  VALID_KANA_NAME_REGEX = /\A[ァ-ヶー－]+\z/
  with_options presence: true, format: { with: VALID_KANA_NAME_REGEX, message: "は全角カナ文字で入力してください" } do
    validates :kana_family_name
    validates :kana_first_name
  end

  has_many :events
  has_many :entries
  has_many :users
  has_many :sns_credentials
  has_many :likes, dependent: :destroy
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to :area

  def update_without_current_password(params, *options)
    params.delete(:current_password)

    if params[:password].blank? && params[:password_confirmation].blank?
      params.delete(:password)
      params.delete(:password_confirmation)
    end

    result = update_attributes(params, *options)
    clean_up_passwords
    result
  end

  def entried_by?(event_id)
    entries.where(event_id: event_id).exists?
  end

  def self.from_omniauth(auth)
    sns = SnsCredential.where(provider: auth.provider, uid: auth.uid).first_or_create
    user = User.where(email: auth.info.email).first_or_initialize(
      nickname: auth.info.name,
        email: auth.info.email
    )
    if user.persisted?
      sns.user = user
      sns.save
    end
    { user: user, sns: sns }
  end

  def already_liked?(event)
    self.likes.exists?(event_id: event.id)
  end

end
