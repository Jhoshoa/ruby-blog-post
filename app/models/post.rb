class Post < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  has_and_belongs_to_many :categories
  has_many :comments, dependent: :destroy

  validates :title, presence: true, length: { minimum: 3 }
  validates :body, presence: true
  validate :acceptable_image

  scope :search, ->(query) {
    where("title LIKE :q OR body LIKE :q", q: "%#{sanitize_sql_like(query)}%") if query.present?
  }

  private

  def acceptable_image
    return unless image.attached?

    unless image.blob.byte_size <= 5.megabytes
      errors.add(:image, "is too large (maximum is 5MB)")
    end

    acceptable_types = ["image/jpeg", "image/png", "image/webp", "image/gif"]
    unless acceptable_types.include?(image.blob.content_type)
      errors.add(:image, "must be a JPEG, PNG, WebP, or GIF")
    end
  end
end
