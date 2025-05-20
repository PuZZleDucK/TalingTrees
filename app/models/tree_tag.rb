class TreeTag < ApplicationRecord
  belongs_to :user
  belongs_to :tree

  ALLOWED_TAGS = %w[good funny friendly unique].freeze

end
