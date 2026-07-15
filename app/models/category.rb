class Category < ApplicationRecord
  has_and_belongs_to_many :posts

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }

  before_validation :generate_slug

  private

  def generate_slug
    self.slug = name.to_s.parameterize if name.present? && slug.blank?
  end
end
