# Clear out any existing data so the seed is idempotent
# Remove associated records in the correct order to avoid foreign key issues
Chat.destroy_all
Tree.destroy_all
User.destroy_all

User.create!(name: 'Admin', email: 'admin@example.com', blurb: 'Initial admin user')
User.create!(name: 'Alice', email: 'alice@example.com', blurb: 'Regular user')
User.create!(name: 'Bob', email: 'bob@example.com', blurb: 'Regular user')
User.create!(name: 'Charlie', email: 'charlie@example.com', blurb: 'Regular user')

User.find_each do |user|
  user.ensure_initial_trees!
end

