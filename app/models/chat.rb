# frozen_string_literal: true

# Stores chat sessions between a user and a tree.
class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :tree
  has_many :messages, dependent: :destroy
end
