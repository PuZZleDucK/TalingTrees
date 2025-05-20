require_relative '../test_helper'
require 'minitest/autorun'

class TreeTagTest < Minitest::Test
  def test_allowed_tags_constant
    assert defined?(TreeTag::ALLOWED_TAGS)
  end

  def test_validates_inclusion
    tag = TreeTag.new(tag: 'good')
    assert_includes TreeTag::ALLOWED_TAGS, tag.tag
  end
end
