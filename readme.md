# Talk to Trees

## Dataset:
https://data.melbourne.vic.gov.au/explore/dataset/trees-with-species-and-dimensions-urban-forest/api/


## Ollama:
https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-chat-completion


## Ollama Gem:
https://github.com/gbaptista/ollama-ai?tab=readme-ov-file#chat-generate-a-chat-completion

## Rails App
This repository contains a minimal Rails application skeleton generated manually due to network restrictions preventing installation of the Rails gem. The structure mirrors a basic `rails new` project and serves as a starting point.

### Setup
1. Install dependencies:
   ```bash
   bundle install
   ```
2. Create and migrate the database:
   ```bash
   bundle exec rails db:create
   bundle exec rails db:migrate
   ```
3. Seed initial users:
   ```bash
   bundle exec rails db:seed
   ```
4. Import tree data (clears existing trees):
   ```bash
   bundle exec rake db:import__trees
   ```
5. Run the test suite:
   ```bash
   ruby test/run_tests.rb
   ```
6. Start the Rails server:
   ```bash
   bundle exec rails server
   ```
