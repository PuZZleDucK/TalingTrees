# frozen_string_literal: true

require 'coverage'
Coverage.start

require 'ostruct'
require 'pathname'
require 'logger'
require 'active_support/core_ext/object/blank'

module ActiveRecord
  class Base
    def self.primary_abstract_class; end
    def self.belongs_to(*); end
    def self.has_many(*); end
  end
end

module ActionController
  class Base
    def self.before_action(*); end
    def self.helper_method(*); end

    attr_accessor :params, :session

    def initialize
      @params = {}
      @session = {}
    end

    def response
      @response ||= Response.new
    end

    def redirect_back(fallback_location: '/'); end

    def head(status)
      status
    end

    def render(json:)
      @rendered = json
    end

    attr_reader :rendered

    Response = Struct.new(:headers, :stream) do
      def initialize
        super({}, Stream.new)
      end
    end

    class Stream
      attr_reader :chunks

      def initialize
        @chunks = []
      end

      def write(chunk)
        @chunks << chunk
      end

      def close; end
    end
  end

  module Live; end

  class Parameters < Hash
    def to_unsafe_h
      self
    end
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

module Rails
  def self.logger
    @logger ||= Logger.new(nil)
  end

  def self.env
    'test'
  end

  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end
end
