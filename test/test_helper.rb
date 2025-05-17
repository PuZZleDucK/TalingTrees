require 'coverage'
Coverage.start

module ActiveRecord
  class Base
    def self.primary_abstract_class; end
  end
end

require_relative '../app/models/application_record'
require_relative '../app/models/tree'
require_relative '../app/models/user'
