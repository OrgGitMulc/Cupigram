class User < ApplicationRecord
  has_secure_password
  has_many :recipe_histories, dependent: :destroy
  # Ensure email is unique
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  
  # For consistent storage
  before_save :normalize_email

  private

  # Converts email to lower case
  def normalize_email
    self.email = email.downcase.strip
  end
end
