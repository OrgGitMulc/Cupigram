class User < ApplicationRecord
  has_secure_password
  has_many :recipe_histories, dependent: :destroy
end
