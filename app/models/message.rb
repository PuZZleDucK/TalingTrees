# frozen_string_literal: true

# Individual message within a chat conversation.
class Message < ApplicationRecord
  belongs_to :chat
end
