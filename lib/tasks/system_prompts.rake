# frozen_string_literal: true

require_relative '../system_prompts'

namespace :db do
  desc 'Assign system prompts to trees based on relationships'
  task system_prompts: :environment do
    Tasks::SystemPrompts.new.run
  end
end
