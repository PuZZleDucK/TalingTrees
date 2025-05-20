class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Provide a lightweight attribute system when ActiveRecord isn't fully
  # loaded (for example, in the lightweight test environment where
  # ActiveRecord::Base is just a stub). When the real ActiveRecord is
  # available we rely on its normal behaviour.
  unless ActiveRecord::Base.respond_to?(:connection)
    def initialize(attrs = {})
      @attributes = {}
      attrs.each { |k, v| send("#{k}=", v) }
    end

    def attributes
      (@attributes || {}).transform_keys(&:to_s)
    end

    def update!(attrs)
      attrs.each { |k, v| send("#{k}=", v) }
    end

    def method_missing(name, *args, &block)
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
