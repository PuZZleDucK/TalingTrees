class ChatsController < ApplicationController
  include ActionController::Live

  def create
    tree = Tree.find(params[:id])
    history = params[:history]
    history = JSON.parse(history) if history.is_a?(String)
    history = [history] if history.is_a?(Hash)

    chat = if params[:chat_id].present?
      Chat.find(params[:chat_id])
    else
      Chat.create!(user: @current_user, tree: tree).tap do |c|
        response.headers['X-Chat-Id'] = c.id.to_s
      end
    end

    history.to_a.each do |msg|
      chat.messages.create!(role: msg['role'], content: msg['content'])
    end

    messages = [{ 'role' => 'system', 'content' => tree.llm_sustem_prompt.to_s }] + history.to_a

    response.headers['Content-Type'] = 'text/event-stream'
    client = Ollama.new(
      credentials: {
        address: ENV.fetch('OLLAMA_URL', 'http://localhost:11434')
      },
      options: {
        server_sent_events: true
      }
    )

    assistant_content = ''

    begin
      client.chat({ model: tree.llm_model, messages: messages }) do |chunk = nil, _raw = nil|
        content = chunk&.dig('message', 'content')
        if content
          assistant_content << content
          response.stream.write(content)
        end
      end
    ensure
      chat.messages.create!(role: 'assistant', content: assistant_content)
      response.stream.close
    end
  end

  def history
    tree = Tree.find(params[:id])
    chat = Chat.where(user: @current_user, tree: tree).order(created_at: :desc).first

    if chat
      messages = chat.messages.order(:created_at).map { |m| { role: m.role, content: m.content } }
      render json: { chat_id: chat.id, messages: messages }
    else
      render json: { chat_id: nil, messages: [] }
    end
  end
end
