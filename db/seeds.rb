# Clear out any existing data so the seed is idempotent
Tree.destroy_all
User.destroy_all

User.create!(name: 'Admin', email: 'admin@example.com', blurb: 'Initial admin user')
User.create!(name: 'Alice', email: 'alice@example.com', blurb: 'Regular user')
User.create!(name: 'Bob', email: 'bob@example.com', blurb: 'Regular user')
User.create!(name: 'Charlie', email: 'charlie@example.com', blurb: 'Regular user')

Tree.create!(name: 'Yggdrasil', treedb_com_id: '123', treedb_common_name: 'Oak', treedb_genus: 'Quercus', treedb_family: 'Fagaceae', treedb_diameter: '30', treedb_date_planted: '2020-01-01', treedb_age_description: 'Young', treedb_useful_life_expectency_value: '50', treedb_precinct: 'Central', treedb_located_in: 'Park', treedb_uploaddate: '2024-01-01', treedb_lat: -37.8136, treedb_long: 144.9631, llm_model: 'Qwen3:latest', llm_sustem_prompt: 'Describe the tree')

Tree.create!(name: 'Treebeard', treedb_com_id: '124', treedb_common_name: 'Maple', treedb_genus: 'Acer', treedb_family: 'Sapindaceae', treedb_diameter: '25', treedb_date_planted: '2019-06-15', treedb_age_description: 'Mature', treedb_useful_life_expectency_value: '60', treedb_precinct: 'North', treedb_located_in: 'Street', treedb_uploaddate: '2024-01-02', treedb_lat: -37.8140, treedb_long: 144.9640, llm_model: 'Qwen3:latest', llm_sustem_prompt: 'Describe the tree')

Tree.create!(name: 'Groot', treedb_com_id: '125', treedb_common_name: 'Pine', treedb_genus: 'Pinus', treedb_family: 'Pinaceae', treedb_diameter: '40', treedb_date_planted: '2015-03-10', treedb_age_description: 'Mature', treedb_useful_life_expectency_value: '70', treedb_precinct: 'East', treedb_located_in: 'Reserve', treedb_uploaddate: '2024-01-03', treedb_lat: -37.8150, treedb_long: 144.9650, llm_model: 'Qwen3:latest', llm_sustem_prompt: 'Describe the tree')

Tree.create!(name: 'Whisper', treedb_com_id: '126', treedb_common_name: 'Eucalyptus', treedb_genus: 'Eucalyptus', treedb_family: 'Myrtaceae', treedb_diameter: '35', treedb_date_planted: '2018-11-20', treedb_age_description: 'Mature', treedb_useful_life_expectency_value: '80', treedb_precinct: 'West', treedb_located_in: 'Park', treedb_uploaddate: '2024-01-04', treedb_lat: -37.8160, treedb_long: 144.9660, llm_model: 'Qwen3:latest', llm_sustem_prompt: 'Describe the tree')
