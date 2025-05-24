#!/usr/bin/env bash
set -e

echo "🌱 Starting Ollama in the background..."
# launch Ollama serve
ollama serve &

# wait for Ollama API to be ready
until nc -z localhost 11434; do
  echo "⏳ waiting for Ollama at localhost:11434..."
  sleep 1
done

echo "✅ Ollama is up! Bootstrapping Rails…"
# run all your data tasks
bundle exec rails db:migrate
bundle exec rails db:seed
bundle exec rake db:import_trees[15]
bundle exec rake db:name_trees
bundle exec rake db:add_relationships
bundle exec rake db:system_prompts

echo "🚀 Handing off to Rails server"
# finally exec the CMD (rails server)
exec "$@"
