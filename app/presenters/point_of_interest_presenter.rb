# frozen_string_literal: true

# Provides helper methods for presenting points of interest in JSON responses.
class PointOfInterestPresenter
  CATEGORY_LABELS = {
    'heritage' => 'Heritage Site', 'ptv_train' => 'Train Station',
    'ptv_tram' => 'Tram Stop', 'ptv_bus' => 'Bus Stop',
    'ptv_interstate' => 'Interstate Coach Stop', 'ptv_skybus' => 'SkyBus Stop'
  }.freeze

  CATEGORY_STYLES = {
    'heritage' => { 'color' => '#b45309', 'fill_color' => '#f59e0b', 'radius' => 6 },
    'ptv_train' => { 'color' => '#1d4ed8', 'fill_color' => '#60a5fa', 'radius' => 5 },
    'ptv_tram' => { 'color' => '#15803d', 'fill_color' => '#4ade80', 'radius' => 5 },
    'ptv_bus' => { 'color' => '#7c3aed', 'fill_color' => '#a855f7', 'radius' => 5 },
    'ptv_interstate' => { 'color' => '#b91c1c', 'fill_color' => '#f87171', 'radius' => 5 },
    'ptv_skybus' => { 'color' => '#0f766e', 'fill_color' => '#2dd4bf', 'radius' => 5 }
  }.freeze

  def self.label_for(category)
    CATEGORY_LABELS.fetch(category) { 'Point of Interest' }
  end

  def self.style_for(category)
    (CATEGORY_STYLES[category] || CATEGORY_STYLES['heritage']).dup
  end
end
