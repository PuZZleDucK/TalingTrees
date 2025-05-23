# frozen_string_literal: true

require_relative '../relationship_builder'

namespace :db do
  desc 'Add relationships between trees'
  task add_relationships: :environment do
    Tasks::RelationshipBuilder.new.run
  end
end
