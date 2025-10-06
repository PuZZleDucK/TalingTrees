# frozen_string_literal: true

# Represents a heritage point of interest sourced from the Victorian Heritage Register.
class PointOfInterest < ApplicationRecord
  CATEGORIES = %w[
    heritage
    ptv_train
    ptv_tram
    ptv_bus
    ptv_interstate
    ptv_skybus
  ].freeze

  if respond_to?(:table_name=)
    self.table_name = 'points_of_interest'
  else
    def self.table_name
      'points_of_interest'
    end
  end
  if respond_to?(:validates)
    validates :site_name, presence: true
    validates :ufi, uniqueness: true, allow_nil: true
    validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  end
end
