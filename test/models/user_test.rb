require_relative '../test_helper'
require 'minitest/autorun'

class UserTest < Minitest::Test
  def test_class_defined
    assert defined?(User)
  end
end
