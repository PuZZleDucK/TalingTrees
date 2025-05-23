# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'

class MessageTest < Minitest::Test
  def test_class_defined
    assert defined?(Message)
  end
end
