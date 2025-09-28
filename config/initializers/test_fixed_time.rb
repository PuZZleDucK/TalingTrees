# frozen_string_literal: true

if Rails.env.test?
  require 'time'
  require 'active_support/testing/time_helpers'

  helper = Object.new.extend(ActiveSupport::Testing::TimeHelpers)

  fixed_time_string = ENV.fetch('TEST_FIXED_TIME', '2025-01-15 12:00:00 UTC')

  fixed_time = begin
    zone = Time.zone || ActiveSupport::TimeZone['UTC']
    zone&.parse(fixed_time_string)
  rescue ArgumentError
    nil
  end

  fixed_time ||= begin
    Time.parse(fixed_time_string)
  rescue ArgumentError
    Time.utc(2025, 1, 15, 12, 0, 0)
  end

  helper.travel_to(fixed_time)

  at_exit { helper.travel_back }
end
