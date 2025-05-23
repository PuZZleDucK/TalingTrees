# frozen_string_literal: true

namespace :db do
  desc 'Assign system prompts to trees based on relationships'
  task system_prompts: :environment do
    base = 'You are a playful talking tree. Stay in character. Hint that you know other trees but only reveal their names when asked.'

    Tree.find_each do |tree|
      prompt = base.dup
      rel_prompt = tree.chat_relationship_prompt.to_s
      prompt += "\n#{rel_prompt}" unless rel_prompt.empty?
      tree.update!(llm_sustem_prompt: prompt)
    end
  end
end
