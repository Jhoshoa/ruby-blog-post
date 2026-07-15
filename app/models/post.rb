class Post < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  has_many :comments, dependent: :destroy

  CATEGORIES = {
    "General" => 0,
    "Technology" => 1,
    "Programming" => 2,
    "Web Development" => 3,
    "Mobile Development" => 4,
    "Data Science" => 5,
    "Artificial Intelligence" => 6,
    "Machine Learning" => 7,
    "DevOps" => 8,
    "Cloud Computing" => 9,
    "Cybersecurity" => 10,
    "Blockchain" => 11,
    "Startups" => 12,
    "Business" => 13,
    "Entrepreneurship" => 14,
    "Finance" => 15,
    "Marketing" => 16,
    "Design" => 17,
    "UX/UI" => 18,
    "Lifestyle" => 19,
    "Health" => 20,
    "Fitness" => 21,
    "Nutrition" => 22,
    "Travel" => 23,
    "Food" => 24,
    "Photography" => 25,
    "Gaming" => 26,
    "Entertainment" => 27,
    "Science" => 28,
    "Education" => 29
  }.freeze

  enum :category, CATEGORIES

  validates :title, presence: true, length: { minimum: 3 }
  validates :body, presence: true
  validate :acceptable_image

  scope :search, ->(query) {
    where("title LIKE :q OR body LIKE :q", q: "%#{sanitize_sql_like(query)}%") if query.present?
  }

  def category_name
    category || "General"
  end

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
