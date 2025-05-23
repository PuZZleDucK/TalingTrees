# frozen_string_literal: true

# Tag applied by a tree to a user.
class UserTag < ApplicationRecord
  belongs_to :tree
  belongs_to :user

  ALLOWED_TAGS = %w[helpful friendly cheeky funny bossy].freeze
end
