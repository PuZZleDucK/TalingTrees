# frozen_string_literal: true

# Clear out any existing data so the seed is idempotent
# Remove associated records in the correct order to avoid foreign key issues
Chat.destroy_all
Tree.destroy_all
User.destroy_all

begin
  require 'blazer'
rescue LoadError
  # ignore if Blazer is not available in this environment
end

User.create!(name: 'Admin', email: 'admin@example.com', blurb: 'Initial admin user')
User.create!(name: 'Alice', email: 'alice@example.com', blurb: 'Regular user')
User.create!(name: 'Bob', email: 'bob@example.com', blurb: 'Regular user')
User.create!(name: 'Charlie', email: 'charlie@example.com', blurb: 'Regular user')

if defined?(Blazer::Query)
  admin = User.find_by(name: 'Admin')

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
