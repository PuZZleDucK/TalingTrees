require_relative '../test_helper'
require 'minitest/autorun'

class TreeTest < Minitest::Test
  def test_class_defined
    assert defined?(Tree)
  end
end
