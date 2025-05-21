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

    system_prompt = tree.llm_sustem_prompt.to_s + tree.chat_relationship_prompt.to_s
    system_prompt += @current_user.chat_tags_prompt if chat.messages.empty?
    messages = [{ 'role' => 'system', 'content' => system_prompt }] + history.to_a

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
      maybe_mark_friendly(chat)
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

  private

  def maybe_mark_friendly(chat)
    user = chat.user
    tree = chat.tree

    count = if Message.respond_to?(:joins)
               Message.joins(:chat).where(role: 'user', chats: { user_id: user.id, tree_id: tree.id }).count
             else
               msgs = Array(Message.records)
               chats = Array(Chat.records)
               msgs.count do |m|
                 next false unless m[:role] == 'user'
                 chat_rec = chats.find { |c| c[:id] == m[:chat_id] }
                 chat_rec && chat_rec[:user_id] == user.id && chat_rec[:tree_id] == tree.id
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
