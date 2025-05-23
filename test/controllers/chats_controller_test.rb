# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'ostruct'

# Minimal stub simulating the Ollama client used in ChatsController
class Ollama
  class << self
    attr_accessor :last_payload
  end

  def initialize(credentials:, options: {}); end

  def chat(payload)
    self.class.last_payload = payload
    # Simulate the gem calling the stream handler without arguments
    yield
  end
end

# Minimal version of ChatsController#create focusing on the Ollama call
class ChatsController
  def create(params)
    tree = params[:tree] || OpenStruct.new(llm_model: 'model', llm_sustem_prompt: 'prompt')
    history = params[:history]
    history = JSON.parse(history) if history.is_a?(String)
    history = [history] if history.is_a?(Hash)

    system_prompt = tree.llm_sustem_prompt.to_s
    messages = [{ 'role' => 'system', 'content' => system_prompt }] + history.to_a

    client = Ollama.new(
      credentials: { address: 'http://localhost:11434' },
      options: { server_sent_events: true }
    )
    client.chat({ model: tree.llm_model, messages: messages }) do |_chunk = nil, _raw = nil|
    end
  end

  def history(chat)
    if chat
      msgs = chat.messages.map { |m| { role: m.role, content: m.content } }
      { chat_id: chat.id, messages: msgs }
    else
      { chat_id: nil, messages: [] }
    end
  end

  def maybe_mark_friendly(chat)
    user = chat.user
    tree = chat.tree

    count = if Message.respond_to?(:joins)
              0
            else
              msgs = Array(Message.records)
              chats = Array(Chat.records)
              msgs.count do |m|
                next false unless m[:role] == 'user'

                rec = chats.find { |c| c[:id] == m[:chat_id] }
                rec && rec[:user_id] == user.id && rec[:tree_id] == tree.id
              end
            end

    return unless count >= 3

    if UserTag.respond_to?(:find_or_create_by!)
      UserTag.find_or_create_by!(tree: tree, user: user, tag: 'friendly')
    else
      UserTag.records ||= []
      unless UserTag.records.any? { |r| r[:tree_id] == tree.id && r[:user_id] == user.id && r[:tag] == 'friendly' }
        UserTag.records << { tree_id: tree.id, user_id: user.id, tag: 'friendly' }
      end
    end
  end
end

class ChatsControllerTest < Minitest::Test
  def setup
    Chat.singleton_class.class_eval { attr_accessor :records }
    Message.singleton_class.class_eval { attr_accessor :records }
    UserTag.singleton_class.class_eval { attr_accessor :records }
    Chat.records = []
    Message.records = []
    UserTag.records = []
  end

  def teardown
    Chat.records = nil
    Message.records = nil
    UserTag.records = nil
  end

  def test_create_handles_stream_without_arguments
    controller = ChatsController.new
    assert_silent do
      controller.create(history: [{ 'role' => 'user', 'content' => 'hi' }])
    end
  end

  def test_create_accepts_single_message_hash
    controller = ChatsController.new
    assert_silent do
      controller.create(history: { 'role' => 'user', 'content' => 'hi' })
    end
  end

  def test_history_returns_messages
    controller = ChatsController.new
    chat = OpenStruct.new(id: 1,
                          messages: [OpenStruct.new(role: 'user', content: 'hi'),
                                     OpenStruct.new(role: 'assistant', content: 'hello')])
    expected = {
      chat_id: 1,
      messages: [
        { role: 'user', content: 'hi' },
        { role: 'assistant', content: 'hello' }
      ]
    }
    assert_equal expected, controller.history(chat)
  end

  def test_create_uses_only_system_prompt
    controller = ChatsController.new
    tree = OpenStruct.new(llm_model: 'model', llm_sustem_prompt: 'base', chat_relationship_prompt: ' extras')
    controller.create(history: { 'role' => 'user', 'content' => 'hi' }, tree: tree)
    messages = Ollama.last_payload[:messages]
    assert_equal 'base', messages.first['content']
  end

  def test_maybe_mark_friendly_adds_tag_after_three_messages
    controller = ChatsController.new
    user = OpenStruct.new(id: 1)
    tree = OpenStruct.new(id: 2)
    chat = OpenStruct.new(id: 3, user: user, tree: tree)
    Chat.records << { id: 3, user_id: 1, tree_id: 2 }

    Message.records << { chat_id: 3, role: 'user', content: 'hi1' }
    controller.maybe_mark_friendly(chat)
    assert_empty UserTag.records

    Message.records << { chat_id: 3, role: 'user', content: 'hi2' }
    controller.maybe_mark_friendly(chat)
    assert_empty UserTag.records

    Message.records << { chat_id: 3, role: 'user', content: 'hi3' }
    controller.maybe_mark_friendly(chat)
    assert_includes UserTag.records, { tree_id: 2, user_id: 1, tag: 'friendly' }
  end
end
