# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../app/presenters/point_of_interest_presenter'

class PointOfInterestPresenterTest < Minitest::Test
  def test_label_for_known_category
    assert_equal 'Train Station', PointOfInterestPresenter.label_for('ptv_train')
    assert_equal 'Heritage Site', PointOfInterestPresenter.label_for('heritage')
  end

  def test_label_for_unknown_category
    assert_equal 'Point of Interest', PointOfInterestPresenter.label_for('mystery')
    assert_equal 'Point of Interest', PointOfInterestPresenter.label_for(nil)
  end

  def test_style_for_known_category
    style = PointOfInterestPresenter.style_for('ptv_tram')
    assert_equal({ 'color' => '#15803d', 'fill_color' => '#4ade80', 'radius' => 5 }, style)
    refute_same style, PointOfInterestPresenter.style_for('ptv_tram')
  end

  def test_style_for_unknown_category
    assert_equal({ 'color' => '#b45309', 'fill_color' => '#f59e0b', 'radius' => 6 },
                 PointOfInterestPresenter.style_for('unknown'))
  end
end
