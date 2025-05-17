User.create!(name: 'Admin', email: 'admin@example.com', blurb: 'Initial admin user')
User.create!(name: 'Alice', email: 'alice@example.com', blurb: 'Regular user')
User.create!(name: 'Bob', email: 'bob@example.com', blurb: 'Regular user')
User.create!(name: 'Charlie', email: 'charlie@example.com', blurb: 'Regular user')

Tree.create!(name: 'Example Tree', treedb_com_id: '123', treedb_common_name: 'Oak', treedb_genus: 'Quercus', treedb_family: 'Fagaceae', treedb_diameter: '30', treedb_date_planted: '2020-01-01', treedb_age_description: 'Young', treedb_useful_life_expectency_value: '50', treedb_precinct: 'Central', treedb_located_in: 'Park', treedb_uploaddate: '2024-01-01', treedb_lat: -37.8136, treedb_long: 144.9631, llm_model: 'gpt-4', llm_sustem_prompt: 'Describe the tree')
