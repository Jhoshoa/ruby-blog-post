class User < ApplicationRecord
  has_secure_password

  has_many :posts, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :password, length: { minimum: 6 }, if: :password_required?

  normalizes :email, with: ->(email) { email.strip.downcase }

  private

  def password_required?
    new_record? || password.present?
  end
end
