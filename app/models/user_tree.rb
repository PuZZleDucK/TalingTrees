# frozen_string_literal: true

# Join table recording which trees a user knows about.
class UserTree < ApplicationRecord
  belongs_to :user
  belongs_to :tree
end
