# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../app/presenters/tree_presenter'

class TreePresenterTest < Minitest::Test
  def setup
    @tree = Struct.new(
      :id,
      :name,
      :treedb_lat,
      :treedb_long,
      :neighbor_ids,
      :friend_ids,
      :same_species_ids
    ).new(1, 'Rooted One', -37.8, 145.0, [2, 3], [4], [5])

    def @tree.tag_counts
      { 'heritage' => 2 }
    end

    def @tree.tags_for_user(_user)
      ['favourite']
    end

    @user = Struct.new(:known_trees).new([Struct.new(:id).new(2), Struct.new(:id).new(5)])
    @presenter = TreePresenter.new(@tree, @user)
  end

  def test_summary_data_includes_counts_and_tags
    data = @presenter.summary_data([2, 4, 5])

    assert_equal 1, data[:id]
    assert_equal 'Rooted One', data[:name]
    assert_equal(-37.8, data[:treedb_lat])
    assert_equal 145.0, data[:treedb_long]
    assert_equal 2, data[:neighbor_total]
    assert_equal 1, data[:neighbor_known]
    assert_equal 1, data[:friend_total]
    assert_equal 1, data[:friend_known]
    assert_equal 1, data[:species_total]
    assert_equal 1, data[:species_known]
    assert_equal({ 'heritage' => 2 }, data[:tag_counts])
    assert_equal ['favourite'], data[:user_tags]
  end

  def test_related_ids_data_maps_tree_names
    Tree.stub(:find, ->(id) { Struct.new(:name).new("Tree #{id}") }) do
      data = @presenter.related_ids_data
      assert_equal([{ id: 2, name: 'Tree 2' }, { id: 3, name: 'Tree 3' }], data[:neighbors])
      assert_equal([{ id: 4, name: 'Tree 4' }], data[:friends])
      assert_equal([{ id: 5, name: 'Tree 5' }], data[:same_species])
    end
  end

  def test_known_ids_for_user_falls_back_to_empty_array
    presenter = TreePresenter.new(@tree, nil)
    assert_equal [], presenter.known_ids_for_user
  end
end
