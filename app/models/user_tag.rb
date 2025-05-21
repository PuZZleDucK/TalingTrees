class UserTag < ApplicationRecord
  belongs_to :tree
  belongs_to :user

  ALLOWED_TAGS = %w[helpful friendly cheeky funny bossy].freeze
end
