# frozen_string_literal: true

# Base class for all ActiveRecord models in the application.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # In the real Rails environment ActiveRecord provides all the attribute
  # handling we need. For the lightweight test environment we stub only the
  # minimal behaviour required. Detect this scenario by checking for the
  # presence of `ActiveRecord::VERSION`, which will only be defined when the
  # ActiveRecord gem is loaded.
  unless ActiveRecord.const_defined?(:VERSION)
    def initialize(attrs = {})
      super()
      @attributes = {}
      attrs.each do |k, v|
        send("#{k}=", v)
      end
    end

    def attributes
      (@attributes || {}).transform_keys(&:to_s)
    end

    def update!(attrs)
      attrs.each { |k, v| send("#{k}=", v) }
    end

    def method_missing(name, *args, &)
      attr = name.to_s
      if attr.end_with?('=')
        (@attributes ||= {})[attr.chomp('=').to_sym] = args.first
      elsif (@attributes ||= {}).key?(name.to_sym)
        @attributes[name.to_sym]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      attr = name.to_s
      (@attributes ||= {}).key?(name.to_sym) ||
        (@attributes ||= {}).key?(attr.chomp('=').to_sym) ||
        super
    end
  end
end
