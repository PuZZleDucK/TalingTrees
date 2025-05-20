class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def initialize(attrs = {})
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
