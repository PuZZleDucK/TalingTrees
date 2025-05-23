# frozen_string_literal: true

require 'coverage'
Coverage.start

module ActiveRecord
  class Base
    def self.primary_abstract_class; end
    def self.belongs_to(*); end
    # rubocop:disable Naming/PredicateName
    def self.has_many(*); end
    # rubocop:enable Naming/PredicateName
  end
end

require_relative '../app/models/application_record'
require_relative '../app/models/tree'
require_relative '../app/models/user'
require_relative '../app/models/chat'
require_relative '../app/models/message'
require_relative '../app/models/tree_relationship'
require_relative '../app/models/user_tree'
require_relative '../app/models/tree_tag'
require_relative '../app/models/user_tag'
