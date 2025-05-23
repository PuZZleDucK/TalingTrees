# frozen_string_literal: true

class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :tree
  has_many :messages, dependent: :destroy
end
