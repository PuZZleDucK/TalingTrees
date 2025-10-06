# frozen_string_literal: true

require 'fileutils'

if Rails.env.production?
  FileUtils.mkdir_p('/data')
end
