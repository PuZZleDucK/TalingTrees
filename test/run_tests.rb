# frozen_string_literal: true

require_relative 'test_helper'
require 'minitest/autorun'
require 'fileutils'
require 'timeout'
require 'socket'

def capture_app_screenshot(root, filename:, seed_script: nil, path: '/', wait_selector: nil, delay_ms: 2000, post_script: nil, select_user_id: nil, target_path: nil, target_wait_selector: nil)
  screenshots_dir = File.join(root, 'screenshots')
  FileUtils.mkdir_p(screenshots_dir)

  fixed_time = ENV.fetch('TEST_FIXED_TIME', '2025-01-15 12:00:00 UTC')

  env = {
    'RAILS_ENV' => 'test',
    'SECRET_KEY_BASE' => ENV.fetch('SECRET_KEY_BASE', 'screenshot-secret'),
    'RAILS_LOG_TO_STDOUT' => 'false',
    'TEST_FIXED_TIME' => fixed_time
  }

  yarn_args = ['yarn', 'install', '--frozen-lockfile']
  unless system(env, *yarn_args, chdir: root)
    warn 'Skipping screenshot capture: yarn install failed.'
    return
  end

  unless system(env, 'bundle', 'exec', 'rails', 'db:prepare', chdir: root, out: File::NULL, err: File::NULL)
    warn 'Skipping screenshot capture: database prepare failed.'
    return
  end

  cleanup_script = <<~RUBY
    Message.delete_all
    Chat.delete_all
    TreeTag.delete_all
    UserTag.delete_all
    TreeRelationship.delete_all
    UserTree.delete_all
    Tree.delete_all
    User.delete_all
    Suburb.delete_all

    if ActiveRecord::Base.connection.adapter_name.downcase.include?('sqlite')
      ActiveRecord::Base.connection.execute('DELETE FROM sqlite_sequence')
    end
  RUBY
  unless system(env, 'bundle', 'exec', 'rails', 'runner', cleanup_script, chdir: root)
    warn 'Skipping screenshot capture: database cleanup failed.'
    return
  end

  if seed_script
    unless system(env, 'bundle', 'exec', 'rails', 'runner', seed_script, chdir: root)
      warn 'Skipping screenshot capture: sample data setup failed.'
      return
    end
  end

  port = ENV.fetch('SCREENSHOT_PORT', '4001')
  server_log = File.join(root, 'log', 'screenshot_server.log')
  FileUtils.mkdir_p(File.dirname(server_log))
  server_cmd = ['bundle', 'exec', 'rails', 'server', '-p', port, '-e', 'test']
  server_pid = spawn(env, *server_cmd, chdir: root, out: server_log, err: server_log)

  begin
    Timeout.timeout(60) do
      loop do
        begin
          TCPSocket.new('127.0.0.1', port.to_i).close
          break
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          sleep 1
        end
      end
    end

    screenshot_env = env.merge(
      'SCREENSHOT_URL' => "http://127.0.0.1:#{port}#{path}",
      'SCREENSHOT_PATH' => File.join(root, 'screenshots', filename),
      'SCREENSHOT_DELAY_MS' => delay_ms.to_s
    )
    screenshot_env['SCREENSHOT_WAIT_SELECTOR'] = wait_selector if wait_selector
    screenshot_env['SCREENSHOT_POST_JS'] = post_script if post_script
    if select_user_id
      screenshot_env['SCREENSHOT_SELECT_USER_ID'] = select_user_id
      if target_path
        screenshot_env['SCREENSHOT_TARGET_URL'] = "http://127.0.0.1:#{port}#{target_path}"
        screenshot_env['SCREENSHOT_TARGET_WAIT_SELECTOR'] = target_wait_selector if target_wait_selector
      end
    end
    unless system(screenshot_env, 'yarn', 'screenshot:homepage', chdir: root)
      warn 'Screenshot capture command failed.'
    end
  ensure
    if server_pid
      Process.kill('TERM', server_pid) rescue nil
      Process.wait(server_pid) rescue nil
    end
  end
rescue StandardError => e
  warn "Screenshot capture encountered an error: #{e.message}"
end

def maybe_generate_screenshot_diff(root, relative_path)
  return unless system('git', 'rev-parse', '--is-inside-work-tree', out: File::NULL, err: File::NULL)

  full_path = File.join(root, relative_path)
  return unless File.exist?(full_path)

  diff_status = system('git', 'diff', '--quiet', '--', relative_path)
  return if diff_status # no diff detected

  script = File.join(root, 'scripts', 'image_diff.sh')
  return unless File.executable?(script)

  system('bash', script, relative_path)
rescue StandardError => e
  warn "Screenshot diff generation failed for #{relative_path}: #{e.message}"
end

Dir[File.join(__dir__, '**/*_test.rb')].each { |f| require_relative f }

Minitest.after_run do
  coverage = Coverage.result
  root = File.expand_path('..', __dir__)
  total_covered = 0
  total_lines = 0
  File.open('coverage.txt', 'w') do |f|
    coverage.each do |file, data|
      next unless file.start_with?(root)
      next if file.include?('/test/')
      next if file.include?('/vendor/bundle/')

      covered_lines = data.count { |line| line&.positive? }
      total_lines_file = data.size
      percent = total_lines_file.positive? ? (covered_lines.to_f / total_lines_file * 100).round(2) : 0
      f.puts "#{file}: #{percent}% (#{covered_lines}/#{total_lines_file})"
      total_covered += covered_lines
      total_lines += total_lines_file
    end
    total_percent = total_lines.positive? ? (total_covered.to_f / total_lines * 100).round(2) : 0
    f.puts "TOTAL: #{total_percent}% (#{total_covered}/#{total_lines})"
  end

  rubocop_output = `bundle exec rubocop --config .rubocop.yml 2>&1`
  File.write('rubocop_report.txt', rubocop_output)

  bundler_audit_output = `bundle exec bundler-audit check 2>&1`
  File.write('bundler_audit_report.txt', bundler_audit_output)

  brakeman_output = `bundle exec brakeman -q 2>&1`
  File.write('brakeman_report.txt', brakeman_output)

  capture_app_screenshot(root, filename: 'home-empty.png', path: '/', wait_selector: 'body')
  maybe_generate_screenshot_diff(root, 'screenshots/home-empty.png')

  populated_seed = <<~RUBY
    ApplicationRecord.transaction do
      admin = User.create!(
        name: 'Admin',
        email: 'admin@example.com',
        blurb: 'Analytics admin'
      )
      user = User.create!(
        name: 'Explorer Alice',
        email: 'alice@example.com',
        lat: -37.8105,
        long: 144.9631
      )

      guide = User.create!(
        name: 'Guide Bob',
        email: 'bob@example.com',
        lat: -37.8112,
        long: 144.9644
      )

      starwood = Tree.create!(
        name: 'Starwood Sentinel',
        treedb_common_name: 'River Red Gum',
        treedb_genus: 'Eucalyptus',
        treedb_family: 'Myrtaceae',
        treedb_lat: -37.8108,
        treedb_long: 144.9632,
        llm_model: 'demo-model',
        llm_system_prompt: 'Guard the park paths with kindness.'
      )

      moonlit = Tree.create!(
        name: 'Moonlit Whisper',
        treedb_common_name: 'Golden Elm',
        treedb_genus: 'Ulmus',
        treedb_family: 'Ulmaceae',
        treedb_lat: -37.8116,
        treedb_long: 144.9650,
        llm_model: 'demo-model',
        llm_system_prompt: 'Speak softly to evening wanderers.'
      )

      harbor = Tree.create!(
        name: 'Harborlight Cedar',
        treedb_common_name: 'Cedar',
        treedb_genus: 'Cedrus',
        treedb_family: 'Pinaceae',
        treedb_lat: -37.8099,
        treedb_long: 144.9614,
        llm_model: 'demo-model',
        llm_system_prompt: 'Share glowstone tales with distant friends.'
      )

      [starwood, moonlit, harbor].each do |tree|
        UserTree.create!(user: user, tree: tree)
      end
      UserTree.create!(user: guide, tree: starwood)
      UserTree.create!(user: guide, tree: moonlit)

      TreeRelationship.create!(tree: starwood, related_tree: moonlit, kind: 'neighbor', tag: 'best-friend')
      TreeRelationship.create!(tree: starwood, related_tree: harbor, kind: 'long_distance', tag: 'secret-friend')
      TreeRelationship.create!(tree: moonlit, related_tree: starwood, kind: 'neighbor', tag: 'best-friend')
      TreeRelationship.create!(tree: harbor, related_tree: starwood, kind: 'long_distance', tag: 'secret-friend')
      TreeRelationship.create!(tree: starwood, related_tree: harbor, kind: 'same_species', tag: 'ally')

      TreeTag.create!(user: user, tree: starwood, tag: 'friendly')
      TreeTag.create!(user: user, tree: moonlit, tag: 'unique')
      TreeTag.create!(user: guide, tree: starwood, tag: 'good')

      UserTag.create!(tree: starwood, user: user, tag: 'helpful')
      UserTag.create!(tree: moonlit, user: user, tag: 'friendly')

      Suburb.create!(
        name: 'Demo Grove',
        boundary: 'POLYGON ((144.9610 -37.8120, 144.9655 -37.8120, 144.9655 -37.8080, 144.9610 -37.8080, 144.9610 -37.8120))',
        tree_count: 3
      )

      chat = Chat.create!(user: user, tree: starwood)
      Message.create!(chat: chat, role: 'user', content: 'Hello Sentinel, how are the neighbors today?')
      Message.create!(chat: chat, role: 'assistant', content: 'Moonlit Whisper is humming with golden light, and Harborlight Cedar sends breezy greetings.')

      Ahoy::Event.delete_all
      Ahoy::Visit.delete_all
      now = Time.current
      5.times do |i|
        visit = Ahoy::Visit.create!(
          visit_token: SecureRandom.uuid,
          visitor_token: SecureRandom.uuid,
          started_at: now - i.days,
          user: admin
        )
        Ahoy::Event.create!(
          visit: visit,
          name: 'Page view',
          properties: { path: '/' },
          time: visit.started_at + 5.minutes,
          user: admin
        )
      end

      if defined?(Blazer::Query)
        visits_query = Blazer::Query.find_or_initialize_by(name: 'Ahoy visits per day')
        visits_query.creator = admin
        visits_query.data_source = 'main'
        visits_query.description = 'Count of Ahoy visits grouped by day (last 30 days).'
        visits_query.statement = <<~SQL
          SELECT date(started_at) AS day,
                 COUNT(*) AS visits
          FROM ahoy_visits
          WHERE started_at IS NOT NULL
          GROUP BY day
          ORDER BY day DESC
          LIMIT 30
        SQL
        visits_query.save!

        events_query = Blazer::Query.find_or_initialize_by(name: 'Ahoy events by name')
        events_query.creator = admin
        events_query.data_source = 'main'
        events_query.description = 'Event volume grouped by event name (top 20).'
        events_query.statement = <<~SQL
          SELECT name,
                 COUNT(*) AS events
          FROM ahoy_events
          GROUP BY name
          ORDER BY events DESC
          LIMIT 20
        SQL
        events_query.save!

        dashboard = Blazer::Dashboard.find_or_initialize_by(name: 'Starter analytics')
        dashboard.creator = admin
        dashboard.save!

        Blazer::DashboardQuery.find_or_create_by!(dashboard: dashboard, query: visits_query) do |dq|
          dq.position = 0
        end

        Blazer::DashboardQuery.find_or_create_by!(dashboard: dashboard, query: events_query) do |dq|
          dq.position = 1
        end
      end
    end
  RUBY

  capture_app_screenshot(root, filename: 'home-demo.png', seed_script: populated_seed, path: '/', wait_selector: '#tree-list')
  maybe_generate_screenshot_diff(root, 'screenshots/home-demo.png')

  capture_app_screenshot(
    root,
    filename: 'home-demo-dark.png',
    seed_script: populated_seed,
    path: '/',
    wait_selector: '#tree-list',
    delay_ms: 3000,
    post_script: "localStorage.setItem('theme', 'dark'); document.documentElement.classList.add('dark'); const t = document.getElementById('theme-toggle'); if (t) { t.textContent = '☀️'; }"
  )
  maybe_generate_screenshot_diff(root, 'screenshots/home-demo-dark.png')

  capture_app_screenshot(
    root,
    filename: 'admin-dashboard.png',
    seed_script: populated_seed,
    path: '/admin',
    wait_selector: 'body.rails_admin',
    delay_ms: 3000,
    select_user_id: '1'
  )
  maybe_generate_screenshot_diff(root, 'screenshots/admin-dashboard.png')

  capture_app_screenshot(
    root,
    filename: 'admin-trees.png',
    seed_script: populated_seed,
    path: '/admin/tree',
    wait_selector: 'body.rails_admin',
    delay_ms: 3000,
    select_user_id: '1'
  )
  maybe_generate_screenshot_diff(root, 'screenshots/admin-trees.png')

  capture_app_screenshot(
    root,
    filename: 'analytics-visits.png',
    seed_script: populated_seed,
    path: '/',
    wait_selector: 'body',
    select_user_id: '1',
    target_path: '/blazer/queries/1-ahoy-visits-per-day',
    target_wait_selector: '#bind',
    delay_ms: 4000,
    post_script: <<~JS
      (async () => {
        const form = document.querySelector('#bind');
        if (form) {
          const button = form.querySelector('input[type="submit"]');
          if (button) {
            button.click();
            await new Promise(resolve => setTimeout(resolve, 2500));
          }
        }
      })();
    JS
  )
  maybe_generate_screenshot_diff(root, 'screenshots/analytics-visits.png')

  capture_app_screenshot(
    root,
    filename: 'analytics-events.png',
    seed_script: populated_seed,
    path: '/',
    wait_selector: 'body',
    select_user_id: '1',
    target_path: '/blazer/queries/2-ahoy-events-by-name',
    target_wait_selector: '#bind',
    delay_ms: 4000,
    post_script: <<~JS
      (async () => {
        const form = document.querySelector('#bind');
        if (form) {
          const button = form.querySelector('input[type="submit"]');
          if (button) {
            button.click();
            await new Promise(resolve => setTimeout(resolve, 2500));
          }
        }
      })();
    JS
  )
  maybe_generate_screenshot_diff(root, 'screenshots/analytics-events.png')
end
