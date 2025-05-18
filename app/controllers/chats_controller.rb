class ChatsController < ApplicationController
  include ActionController::Live

  def create
    tree = Tree.find(params[:id])
    history = params[:history].is_a?(String) ? JSON.parse(params[:history]) : params[:history]
    messages = [{ "role" => "system", "content" => tree.llm_sustem_prompt.to_s }] + Array(history)

    response.headers['Content-Type'] = 'text/event-stream'
    client = Ollama.new

    begin
      client.chat(model: tree.llm_model, messages: messages, stream: lambda { |chunk|
        content = chunk.dig('message', 'content')
        response.stream.write(content.to_s)
      })
    ensure
      response.stream.close
    end
  end
end
