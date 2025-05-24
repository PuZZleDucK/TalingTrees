#!/usr/bin/env bash
set -e

# 1) Start Ollama server
ollama serve &

# 2) Wait for it to be ready
echo "⏳ Waiting for Ollama to spin up…"
sleep 5

ollama pull Qwen3:0.6b

# 3) Now run all your Rails/Rake setup
bundle exec rails db:migrate
# bundle exec rails db:seed
# bundle exec rake db:import_trees[15]
# bundle exec rake db:name_trees
# bundle exec rake db:add_relationships
# bundle exec rake db:system_prompts

# 4) Finally, launch Rails
exec bundle exec rails server -b 0.0.0.0
