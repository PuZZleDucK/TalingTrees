# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require_relative '../../app/controllers/application_controller'

class ApplicationControllerTest < Minitest::Test
  def test_update_location_updates_user
    user = User.new
    controller = ApplicationController.new
    controller.instance_variable_set(:@current_user, user)
    controller.params = { lat: 1.5, long: 2.5 }
    controller.update_location
    assert_equal 1.5, user.lat
    assert_equal 2.5, user.long
  end

  def test_know_tree_adds_tree_to_user
    user = User.new(id: 1)
    tree = Tree.new(id: 2)

    Tree.singleton_class.class_eval do
      attr_accessor :records

      def find_by(id:)
        Array(records).find { |t| t.id == id }
      end
    end

    UserTree.singleton_class.class_eval do
      attr_accessor :records

      def find_or_create_by!(user:, tree:)
        self.records ||= []
        rec = records.find { |r| r[:user] == user && r[:tree] == tree }
        unless rec
          rec = { user: user, tree: tree }
          records << rec
        end
        rec
      end
    end

    Tree.records = [tree]
    UserTree.records = []

    controller = ApplicationController.new
    controller.instance_variable_set(:@current_user, user)
    controller.params = { id: 2 }
    controller.know_tree

    assert_includes UserTree.records, { user: user, tree: tree }
  ensure
    Tree.records = nil
    UserTree.records = nil
  end
end
