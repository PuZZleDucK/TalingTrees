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
[x] add tailwind and style tree list page
[x] tree names should be blank when importing
[x] naming script should not pass in the treedb id and don't debug the raw response and add a linebreak between trees
[x] naming script verification step1 (< 150chars and > 2 chars)
[x] naming script verification step2 (llm approves... prompt the same llm in a new chat to verify the response is a single name)
[x] add a function to find other trees within x meters. When a tree is selected to chat count the trees within 10 meters and show this count next to the tree name in chat like this "Tree Name (<count> neighbors). also create a highlighted radius on the map showing the 10 meters
[ ] add rake task to add relationships between trees - neighbors (within 10) - all with same species - 3 random long distance friends
[ ] trees should be able to tag users and users should be able to tag trees (limited tag list)
[ ] relationships have tags too
[ ] naming script should establish relationships
[ ] naming script should find neighbors within 50m and avoid duplicate names
[ ] all lat/long to User and get from device
[ ] users should only see a few trees at the start
[ ] talking to trees should reveal more trees (mostly near, some distant or same species)
[ ] trees should have missions/objectives that users can help with
[ ] dark mode