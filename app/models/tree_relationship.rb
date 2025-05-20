class TreeRelationship < ApplicationRecord
  belongs_to :tree
  belongs_to :related_tree, class_name: 'Tree'

  TAGS = %w[best-friend nemesis secret-friend lost-friend].freeze
end
