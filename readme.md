# Talk to Trees

## Dataset:
https://data.melbourne.vic.gov.au/explore/dataset/trees-with-species-and-dimensions-urban-forest/api/


## Ollama:
https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-chat-completion


## Ollama Gem:
https://github.com/gbaptista/ollama-ai?tab=readme-ov-file#chat-generate-a-chat-completion

## Setup
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
   bundle exec rake db:import_trees
   ```
5. Run the test suite:
   ```bash
   ruby test/run_tests.rb
   ```
6. Start the Rails server:
   ```bash
   bundle exec rails server
   ```
## Todos
[ ] name should be blank when importing
[ ] naming script needs a verification step (llm approves and < 150chars and > 2 chars)
[ ] naming script should find neighbors within 50m and avoid duplicate names
[ ] trees should be able to tag users and users should be able to tag trees (limited tag list)
[ ] add relationships between trees - neighbors - species - random friends
[ ] naming script should establish relationships
[ ] users should only see a few trees at the start
[ ] talking to trees should reveal more trees (mostly near, some distant or same species)
[ ] trees should have missions/objectives that users can help with