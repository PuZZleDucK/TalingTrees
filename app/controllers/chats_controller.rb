# frozen_string_literal: true

# Handles chat interactions between users and trees using server sent events.
class ChatsController < ApplicationController
  include ActionController::Live

  def create
    tree = Tree.find(params[:id])
    history = parse_history(params[:history])
    chat = find_or_create_chat(tree)
    add_history(chat, history)
    messages = build_messages(tree, chat, history)

    assistant_content = stream_chat(tree, messages)

    chat.messages.create!(role: 'assistant', content: assistant_content)
    maybe_mark_friendly(chat)
  ensure
    response.stream.close
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
    return unless user_message_count(chat) >= 3

    create_friendly_tag(chat.user, chat.tree)
  end

  def parse_history(hist)
    hist = JSON.parse(hist) if hist.is_a?(String)
    hist = [hist] if hist.is_a?(Hash)
    Array(hist).map do |msg|
      if msg.is_a?(ActionController::Parameters)
        msg = msg.to_unsafe_h
      end
      { 'role' => msg['role'], 'content' => msg['content'] }
    end
  end

  def find_or_create_chat(tree)
    if params[:chat_id].present?
      Chat.find(params[:chat_id])
    else
      Chat.create!(user: @current_user, tree: tree).tap do |c|
        response.headers['X-Chat-Id'] = c.id.to_s
      end
    end
  end

  def add_history(chat, history)
    history.to_a.each do |msg|
      chat.messages.create!(role: msg['role'], content: msg['content'])
    end
  end

  def build_messages(tree, chat, history)
    system_prompt = tree.llm_sustem_prompt.to_s
    system_prompt += @current_user.chat_tags_prompt if chat.messages.empty?
    [{ 'role' => 'system', 'content' => system_prompt }] + history.to_a
  end

  def stream_chat(tree, messages)
    response.headers['Content-Type'] = 'text/event-stream'
    client = Ollama.new(
      credentials: { address: ENV.fetch('OLLAMA_URL', 'http://localhost:11434') },
      options: { server_sent_events: true }
    )

    model = tree.llm_model.presence || default_llm_model

    Rails.logger.info("[Ollama] Requesting chat for tree #{tree.id} using model #{model}")
    Rails.logger.debug("[Ollama] Messages: #{messages.inspect}")

    assistant_content = ''
    client.chat({ model: model, messages: messages }) do |chunk = nil, _raw = nil|
      content = chunk&.dig('message', 'content')
      next unless content

      Rails.logger.debug("[Ollama] Received chunk: #{content}")
      assistant_content << content
      response.stream.write(content)
    end
    Rails.logger.info("[Ollama] Completed chat for tree #{tree.id}")
    assistant_content
  end

  def default_llm_model
    env = Rails.env || 'development'
    config = YAML.load_file(Rails.root.join('config', 'llm.yml'), aliases: true)
    config.fetch(env, {})['final_model']
  rescue StandardError => e
    Rails.logger.error("[Chat] Failed to load default model: #{e}")
    nil
  end

  def user_message_count(chat)
    user = chat.user
    tree = chat.tree
    if Message.respond_to?(:joins)
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
  end

  def create_friendly_tag(user, tree)
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
