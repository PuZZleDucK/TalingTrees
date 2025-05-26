# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../app/controllers/chats_controller'

# Minimal stub simulating the Ollama client used in ChatsController
class Ollama
  class << self
    attr_accessor :last_payload, :response_chunks
  end

  def initialize(credentials:, options: {}); end

  def chat(payload, &)
    self.class.last_payload = payload
    chunks = self.class.response_chunks || [nil]
    chunks.each(&)
  end
end

# Helper association for storing messages on Chat records in tests
class MessagesAssoc
  def initialize(chat)
    @chat = chat
    @records = []
  end

  def create!(attrs)
    msg = Message.new(attrs)
    @records << msg
    Message.records << { chat_id: @chat.id, role: attrs[:role], content: attrs[:content] }
    msg
  end

  def order(*_args)
    @records
  end

  def map(&)
    @records.map(&)
  end

  def empty?
    @records.empty?
  end
end

class ChatsControllerTest < Minitest::Test
  def setup
    Chat.singleton_class.class_eval do
      attr_accessor :records

      def create!(attrs)
        self.records ||= []
        chat = Chat.new(attrs.merge(id: (records.size + 1)))
        chat.define_singleton_method(:messages) { @messages ||= MessagesAssoc.new(self) }
        records << { id: chat.id, user_id: attrs[:user].id, tree_id: attrs[:tree].id, obj: chat }
        chat
      end

      def where(user:, tree:)
        Array(records).select { |r| r[:user_id] == user.id && r[:tree_id] == tree.id }.map { |r| r[:obj] }.tap do |arr|
          def arr.order(*)
            self
          end
        end
      end

      def find(id)
        rec = Array(records).find { |r| r[:id] == id }
        rec && rec[:obj]
      end
    end

    Tree.singleton_class.class_eval do
      attr_accessor :records

      def find(id)
        Array(records).find { |t| t.id == id }
      end
    end

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
    Tree.records = nil
  end

  def test_create_handles_stream_without_arguments
    tree = Tree.new(id: 1, llm_model: 'model', llm_system_prompt: 'prompt')
    Tree.records = [tree]

    controller = ChatsController.new
    controller.instance_variable_set(:@current_user, User.new(id: 1))
    controller.params = { id: 1, history: [{ 'role' => 'user', 'content' => 'hi' }] }

    assert_silent { controller.create }
  ensure
    Tree.records = nil
  end

  def test_create_accepts_single_message_hash
    tree = Tree.new(id: 1, llm_model: 'model', llm_system_prompt: 'prompt')
    Tree.records = [tree]
    controller = ChatsController.new
    controller.instance_variable_set(:@current_user, User.new(id: 1))
    controller.params = { id: 1, history: { 'role' => 'user', 'content' => 'hi' } }
    assert_silent { controller.create }
  ensure
    Tree.records = nil
  end

  def test_create_accumulates_response_content
    tree = Tree.new(id: 1, llm_model: 'model', llm_system_prompt: 'prompt')
    Tree.records = [tree]
    controller = ChatsController.new
    controller.instance_variable_set(:@current_user, User.new(id: 1))
    controller.params = { id: 1, history: { 'role' => 'user', 'content' => 'hi' } }
    Ollama.response_chunks = [
      { 'message' => { 'content' => 'hello ' } },
      { 'message' => { 'content' => 'world' } }
    ]
    controller.create
    assert_equal 'hello world', controller.response.stream.chunks.join
    chat = Chat.records.last[:obj]
    assert_equal 'hello world', chat.messages.map(&:content).last
  ensure
    Ollama.response_chunks = nil
    Tree.records = nil
  end

  def test_history_returns_messages
    user = User.new(id: 1)
    tree = Tree.new(id: 2)

    Tree.records = [tree]

    chat = Chat.new(id: 1, user: user, tree: tree)
    chat.define_singleton_method(:messages) { @messages ||= MessagesAssoc.new(chat) }
    chat.messages.create!(role: 'user', content: 'hi')
    chat.messages.create!(role: 'assistant', content: 'hello')
    Chat.records << { id: 1, user_id: 1, tree_id: 2, obj: chat }

    controller = ChatsController.new
    controller.instance_variable_set(:@current_user, user)
    controller.params = { id: 2 }
    controller.history

    expected = {
      chat_id: 1,
      messages: [
        { role: 'user', content: 'hi' },
        { role: 'assistant', content: 'hello' }
      ]
    }

    assert_equal expected, controller.rendered
  ensure
    Chat.records = nil
    Tree.records = nil
  end

  def test_create_uses_only_system_prompt
    tree = Tree.new(id: 1, llm_model: 'model', llm_system_prompt: 'base', chat_relationship_prompt: ' extras')
    Tree.records = [tree]
    controller = ChatsController.new
    controller.instance_variable_set(:@current_user, User.new(id: 1))
    controller.params = { id: 1, history: { 'role' => 'user', 'content' => 'hi' } }
    controller.create
    messages = Ollama.last_payload[:messages]
    assert_equal 'base', messages.first['content']
  ensure
    Tree.records = nil
  end

  def test_maybe_mark_friendly_adds_tag_after_three_messages
    controller = ChatsController.new
    user = User.new(id: 1)
    tree = Tree.new(id: 2)
    chat = Chat.new(id: 3, user: user, tree: tree)
    Chat.records << { id: 3, user_id: 1, tree_id: 2, obj: chat }

    Message.records << { chat_id: 3, role: 'user', content: 'hi1' }
    controller.send(:maybe_mark_friendly, chat)
    assert_empty UserTag.records

    Message.records << { chat_id: 3, role: 'user', content: 'hi2' }
    controller.send(:maybe_mark_friendly, chat)
    assert_empty UserTag.records

    Message.records << { chat_id: 3, role: 'user', content: 'hi3' }
    controller.send(:maybe_mark_friendly, chat)
    assert_includes UserTag.records, { tree_id: 2, user_id: 1, tag: 'friendly' }
  end
end
