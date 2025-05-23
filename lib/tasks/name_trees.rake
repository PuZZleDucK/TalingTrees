# frozen_string_literal: true

require_relative '../name_trees'

namespace :db do
  desc 'Assign fun, kid-friendly names to trees using local Ollama'
  task name_trees: :environment do
    Tasks::NameTrees.new.run
  end
end
