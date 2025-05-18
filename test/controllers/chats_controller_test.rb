require_relative '../test_helper'
require 'minitest/autorun'
require 'ostruct'

# Minimal stub simulating the Ollama client used in ChatsController
class Ollama
  def initialize(credentials:, options: {}); end
  def chat(model:, messages:, stream: nil)
    # Simulate the observed error from the real gem
    raise ArgumentError, 'wrong number of arguments (given 0, expected 1)'
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
    client.chat(model: tree.llm_model, messages: messages, stream: lambda { |_chunk| })
  end
end

class ChatsControllerTest < Minitest::Test
  def test_create_raises_error
    controller = ChatsController.new
    controller.create(history: [{ 'role' => 'user', 'content' => 'hi' }])
  end
end
