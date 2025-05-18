require_relative '../test_helper'
require 'minitest/autorun'

class ChatTest < Minitest::Test
  def test_class_defined
    assert defined?(Chat)
  end
end
