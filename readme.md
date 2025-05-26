# Talk to Trees

See [CHANGELOG.md](CHANGELOG.md) for recent updates.

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
2. Install Node packages:
   ```bash
   yarn install --immutable
   ```
3. Install or update Ollama and download the models:
   ```bash
   bundle exec rake ollama:setup
   ```
4. Create and migrate the database:
   ```bash
   bundle exec rails db:create
   bundle exec rails db:migrate
   ```
5. Seed initial users:
   ```bash
   bundle exec rails db:seed
   ```
6. Download tree data:
   ```bash
   bundle exec rake db:download_trees
   ```
7. Import the downloaded tree data (clears existing trees):
   ```bash
   bundle exec rake db:import_trees
   ```
   The prompts and models used when naming trees are configured in `config/llm.yml`.
8. Name the trees:
   ```bash
   bundle exec rake db:name_trees
   ```
9. Add tree relationships:
   ```bash
   bundle exec rake db:add_relationships
   ```
10. Generate system prompts:
   ```bash
   bundle exec rake db:system_prompts
   ```
   This task now calls the configured LLM to craft a unique personality prompt for each tree based on its name and relationships.
11. Run the test suite:
   ```bash
   ruby test/run_tests.rb
   ```
   bundler-audit and Brakeman will run automatically but you can run them manually with:
   ```bash
   bundle exec bundler-audit check
   bundle exec brakeman -q
   ```

12. Build css:
   ```bash
   yarn build:css
   ```

13. Start the Rails server:
   ```bash
   ./bin/dev
   ```

When running the app you can toggle dark mode using the moon/sun icon in the navigation bar. Your preference is saved in local storage.
Use the search box above the tree list to quickly filter by name.

## Deployment
Deployed to Koyeb: https://visiting-raynell-puzzleduck-f206ac43.koyeb.app/
When deploying or running in production, ensure the `SECRET_KEY_BASE` environment
variable is set. The provided Dockerfile sets a default, but other environments
must configure this value manually.

## Todos
[x] add tailwind and style tree list page
[x] tree names should be blank when importing
[x] naming script should not pass in the treedb id and don't debug the raw response and add a linebreak between trees
[x] naming script verification step1 (< 150chars and > 2 chars)
[x] naming script verification step2 (llm approves... prompt the same llm in a new chat to verify the response is a single name)
[x] add a function to find other trees within x meters. When a tree is selected to chat count the trees within 20 meters and show this count next to the tree name in chat like this "Tree Name (<count> neighbors). also create a highlighted radius on the map showing the 20 meters
[x] add rake task to add relationships between trees - neighbors (within 20) - all with same species - 3 random long distance friends
[x] naming script should find trees within 100m and avoid duplicate names
[x] add lat/long to User and get from device. display it in the nav bar
[x] add relation model between users and the trees they know about. users should only see the closest five trees at the start
[x] when a user chats with a tree, the tree should be given knowledge about it's neighbors and friends personal names and should be encouraged to casually mention them by their FULL personal names
[x] the naming task should skip any trees that already have a name
[x] when a tree response contains a personal name of a tree they know it should be in bold green text and the user should now know about the new tree if they did not already know it
[x] clicking on the bold green name of a tree in a chat should highlight that tree on the map
[x] in the heading of the chat trees should show their neighbors and friends total counts and the number the user knows (eg "Bark Apple Tree Street (2/5 neighbors - 1/3 friends)"). trees should be given a random number of friends (1-6) in the relationships task
[x] users should be able to tag trees (limited tag list - good, funny, friendly, unique, ...)
[x] tags a user gives a tree should be shown under its title
[x] relationships have tags too (eg best-friend, nemesis, secret-friend, lost-friend, ...). allocate some tags randomly when generating relationships
[x] trees should be able to tag users (helpful, friendly, cheeky, funny, bossy, ...)
[x] display user tags in the nav bar to the left of their name. trees should be given the users tags as additional context in the first chat with a user, it should be framed as things the tree has heard from other trees
[x] trees should know more about their neighbors and friends in their context (species, tags, relation types...)
[x] trees should not allow their thoughts to be expanded unless they are tagged friendly
[x] user tags should be colored pills. if a user has a tag applied by many trees it should show one tag with a counter of how many times it's applied.
[x] user tags should display and update without having to reload
[x] trees should be given the context of the users tags and which trees applied those tags to the user
[x] the llm naming the trees should be given the reasons for previous rejections failure in it's prompt
[x] tree names should be more like fantasy character names
[x] update import trees job to take an optional parameter to limit the import count.
[x] when creating trees the system prompt should be blank. create a script to give trees a system prompt. update readme to specify setting up db: seed -> import trees -> name trees -> add relations -> system prompts
[x] tree system prompts should encourage the roleplay of the tree character. should encourage trees to hint at trees they know and only reveal them when asked.
[x] move info about tree relations to the tree system prompts
[x] if a tree has been tagd by any user, it should show a count of the number of times they have been tagged rather than just showing the current user tags
[x] users should be able to tag a tree by clicking on the tag showing how many other users have tagged the tree
[x] users should be able to remove tags they applied to a tree by clicking a trash icon in the pill showing the counter
[x] when the user hovers over the neighbors or friends count in the title of the chat title a dropdown with the list of related trees should appear with ones not known by the user in light grey with the text "unknown"
[x] make zooming more smooth and slightly overzoom when zooming out to reveal new trees
[x] make the found-a-new-tree animation size relative to zoom (larger diameter highlight rings)
[x] the cursor should change to the same as a link when the user hovers over a green tree name in the chat
[x] in the chat title, the trees neighbors and friends count has a hovertip with a list of trees or unknown. the hover should happen when the mouse hovers over the counts or the text, and the known names should be in green and clickable to go to a chat with that tree
[x] we should keep track of the last tree the user spoke to when they move to a new chat and above the title of the chat we should show a "back to <tree-name>" button that returns them to chatting with the last tree
[x] when a user is chatting with a tree, and that tree has revealed neighbors and friends, those neighbors and friends should have a green ring highlighting them on the map. there should also be a green line connecting the current tree with the revealed neighbors and friends.
[x] the line connecting the trees should be labeled with the relation type and have a color based on the relation type
[x] move naming and checking prompts and llm models to a config file
[x] create task to setup ollama and download configured models
[x] cleanup punctuation in tree names
[x] add brakeman report to github action as another new comment
[x] address brakeman issues
[x] add bundler-audit report to github action as another new comment
[x] address bundler-audit issues
[x] add rubocop report to github action as another new comment
[x] address rubocop issues
[x] create new github action to trigger deploy to Keyob on merge to master
[x] review agents-advice.md and create AGENTS.md for project
[x] get test coverage up to 50%
[x] add a dark mode toggle to the nav bar and allow users to toggle the mode
[x] when showing tree relations in the title bar, we should still have the three counts in the title, but the popup should list all trees along with the relation type if the user knows of the trees in the list (i.e. not unknown)
[x] update tree name rating scale for llm
[x] update tree naming prompt to align with rating guidance
[x] update system prompt to be generated by an llm with guidance based on name, relations and other data
[x] add logging for system prompt generation and filter out <think> tags from prompts
[x] stop assigning a system prompt when naming trees
[x] system prompt generation validates structure and retries until valid
[x] update or add system prompt llm rating check
[ ] update system prompt generation to align with rating guidance
[ ] create a database table for storing bounding boxes for melbourne suburbs and populate the table with data from ...
[ ] when naming trees we should use lat/long data to lookup suburb and relative location in it. also save those details to the db for later use
[ ] when naming trees we should use lat/long data to lookup nearby landmarks. also save those details to the db for later use
[ ] when naming trees we should use lat/long data to lookup nearby streets. also save those details to the db for later use
[ ] replace the map pin icons with discs with a tree icon inside the disc (use the tree from the navbar for now)
[ ] trees should have missions/objectives that users can help with... find my enemy, find my lost friend, ... (tree must have relation)
[ ] update system prompt generation to incorporate missions
[ ] new tree mission: find the only... tree of a species, tree planted on x date, ... (must be unique in db)
[ ] new tree mission: find all the ... trees named bob, trees of a species, trees on x road, trees in x park, ... (must be less than 6 in db)
[ ] custom tree images - trees have images that start as the default logo, but users with the right tags could take a selfie of the tree and update it's image
[ ] get test coverage up
[ ] address remaining RuboCop warnings
