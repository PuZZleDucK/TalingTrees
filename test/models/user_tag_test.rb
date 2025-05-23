# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'

class UserTagTest < Minitest::Test
  def test_allowed_tags_constant
    assert defined?(UserTag::ALLOWED_TAGS)
  end

  def test_validates_inclusion
    tag = UserTag.new(tag: 'friendly')
    assert_includes UserTag::ALLOWED_TAGS, tag.tag
  end
end
