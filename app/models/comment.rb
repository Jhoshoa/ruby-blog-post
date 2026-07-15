class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: true

  validates :body, presence: true, length: { maximum: 1000 }

  scope :recent, -> { order(created_at: :desc) }

  def editable_by?(user)
    self.user == user || post.user == user
  end
end
