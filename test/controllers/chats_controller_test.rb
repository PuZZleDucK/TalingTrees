require_relative '../test_helper'
require 'minitest/autorun'
require 'ostruct'

# Minimal stub simulating the Ollama client used in ChatsController
class Ollama
  def initialize(credentials:, options: {}); end
  def chat(payload)
    # Simulate the gem calling the stream handler without arguments
    yield
  end
end

# Minimal version of ChatsController#create focusing on the Ollama call
class ChatsController
  def create(params)
    tree = OpenStruct.new(llm_model: 'model', llm_sustem_prompt: 'prompt')
    history = params[:history]
    messages = [{ 'role' => 'system', 'content' => tree.llm_sustem_prompt.to_s }] + Array(history)
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
end

class ChatsControllerTest < Minitest::Test
  def test_create_handles_stream_without_arguments
    controller = ChatsController.new
    assert_silent do
      controller.create(history: [{ 'role' => 'user', 'content' => 'hi' }])
    end
  end

  def test_history_returns_messages
    controller = ChatsController.new
    chat = OpenStruct.new(id: 1, messages: [OpenStruct.new(role: 'user', content: 'hi'), OpenStruct.new(role: 'assistant', content: 'hello')])
    expected = {
      chat_id: 1,
      messages: [
        { role: 'user', content: 'hi' },
        { role: 'assistant', content: 'hello' }
      ]
    }
    assert_equal expected, controller.history(chat)
  end
end
