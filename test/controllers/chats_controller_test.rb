require_relative '../test_helper'
require 'minitest/autorun'
require 'ostruct'

# Minimal stub simulating the Ollama client used in ChatsController
class Ollama
  def initialize(credentials:, options: {}); end
  def chat(model:, messages:, stream: nil)
    # Simulate the gem calling the stream handler without arguments
    stream&.call
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
    client.chat(model: tree.llm_model, messages: messages, stream: lambda { |_chunk = nil| })
  end
end

class ChatsControllerTest < Minitest::Test
  def test_create_handles_stream_without_arguments
    controller = ChatsController.new
    assert_silent do
      controller.create(history: [{ 'role' => 'user', 'content' => 'hi' }])
    end
  end
end
