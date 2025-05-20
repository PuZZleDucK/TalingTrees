class TreeRelationship < ApplicationRecord
  belongs_to :tree
  belongs_to :related_tree, class_name: 'Tree'
end
