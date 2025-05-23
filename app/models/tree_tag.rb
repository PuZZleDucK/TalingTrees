# frozen_string_literal: true

# Tag applied by a user to a tree.
class TreeTag < ApplicationRecord
  belongs_to :user
  belongs_to :tree

  ALLOWED_TAGS = %w[good funny friendly unique].freeze
end
