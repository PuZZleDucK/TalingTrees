require_relative '../test_helper'
require 'minitest/autorun'

class UserTreeTest < Minitest::Test
  def test_class_defined
    assert defined?(UserTree)
  end
end
