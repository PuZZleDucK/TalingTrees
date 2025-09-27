# Talk to Trees

See [CHANGELOG.md](CHANGELOG.md) for recent updates.
![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/PuZZleDucK/TalingTrees?utm_source=oss&utm_medium=github&utm_campaign=PuZZleDucK%2FTalingTrees&labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit+Reviews)

## Dataset:
https://data.melbourne.vic.gov.au/explore/dataset/trees-with-species-and-dimensions-urban-forest/api/

## Ollama:
https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-chat-completion

## Ollama Gem:
https://github.com/gbaptista/ollama-ai?tab=readme-ov-file#chat-generate-a-chat-completion

## Setup

### Docker (recommended)
1. Build the image:
   ```bash
   docker build -t talingtrees:latest .
   ```
2. Run the container and expose the app on port 3000:
   ```bash
   docker run -p 3000:3000 --name talingtrees talingtrees:latest
   ```
3. Open `http://localhost:3000` in your browser. When finished, stop and remove the container:
   ```bash
   docker stop talingtrees
   docker rm talingtrees
   ```

   The administrative dashboard is available at `http://localhost:3000/admin` and is powered by RailsAdmin.
### Local development (optional)
Only follow these steps if you need to run the app outside Docker.

1. Install dependencies:
   ```bash
   asdf plugin add ruby
   asdf install ruby 3.2.3
   asdf set ruby 3.2.3
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt install -y libyaml-dev libgeos-dev nodejs yarn

   bundle install
   bundle exec rake ollama:setup
   ```
   *If Ollama is already installed locally, ensure the default model is available with* `ollama pull qwen3:0.6b`.

2. Install Node packages (requires Yarn 1 via corepack):
   ```bash
   corepack enable
   corepack prepare yarn@1.22.19 --activate
   yarn install --frozen-lockfile
   ```

3. Download or update data (optional):
   ```bash
   bundle exec rake db:download_trees
   bundle exec rake db:download_vic_suburbs
   ```

4. Create database:
   ```bash
   bundle exec rails db:create
   bundle exec rails db:migrate
   bundle exec rails db:seed
   bundle exec rake db:import_trees
   bundle exec rake db:import_suburbs

   bundle exec rake db:name_trees
   bundle exec rake db:add_relationships
   bundle exec rake db:system_prompts
   ```
   *Suburbs with no trees are skipped during import and each suburb stores how many trees fall within its boundary.*

5. Testing:
   ```bash
   ruby test/run_tests.rb
   ```
   todo: add rubocop and minitest commands
   bundler-audit and Brakeman will run automatically but you can run them manually with:
   ```bash
   bundle exec bundler-audit check
   bundle exec brakeman -q
   ```
   The test runner also provisions a headless browser to capture `screenshots/home-empty.png` (empty state), `screenshots/home-demo.png` (sample data with relations), `screenshots/home-demo-dark.png` (same sample data in dark mode), plus RailsAdmin views `screenshots/admin-dashboard.png` and `screenshots/admin-trees.png` for visual regression reference.

6. Build css and frontend assets:
   ```bash
   bundle exec rails assets:precompile
   yarn build:css
   ```

7. Start the Rails server:
   ```bash
   ./bin/dev
   ```

## Deployment
Deployed to Koyeb: https://visiting-raynell-puzzleduck-f206ac43.koyeb.app/
When deploying or running in production, ensure the `SECRET_KEY_BASE` environment
variable is set. The provided Dockerfile sets a default, but other environments
must configure this value manually.

## Todos

See [TODO.md](TODO.md) for the current backlog.
