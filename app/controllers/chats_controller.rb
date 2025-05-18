class ChatsController < ApplicationController
  include ActionController::Live

  def create
    tree = Tree.find(params[:id])
    history = params[:history].is_a?(String) ? JSON.parse(params[:history]) : params[:history]
    messages = [{ "role" => "system", "content" => tree.llm_sustem_prompt.to_s }] + Array(history)

    response.headers['Content-Type'] = 'text/event-stream'
    client = Ollama.new(
      credentials: {
        address: ENV.fetch('OLLAMA_URL', 'http://localhost:11434')
      },
      options: {
        server_sent_events: true
      }
    )

    begin
      client.chat(model: tree.llm_model, messages: messages) do |chunk|
        content = chunk.dig('message', 'content')
        response.stream.write(content.to_s)
      end
    ensure
      response.stream.close
    end
  end
end
