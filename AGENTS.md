# Project Guidance for Codex Agents

This repository contains a Rails 7 application built with Ruby 3.2.3. Follow these instructions when contributing with an AI agent.

## Deployment
- Production runs on Render at <https://talingtrees-382v.onrender.com/>.
- Render configuration:
  - Runtime: native Ruby with a persistent disk mounted at `/data` for SQLite.
  - Build command: `./bin/render-build.sh` (installs bundle, yarn, precompiles assets).
  - Start command: `mkdir -p /data && bundle exec rails db:migrate && bundle exec rails server -p $PORT -b 0.0.0.0`.
  - Environment variables: `RAILS_MASTER_KEY`, `RAILS_ENV=production`, `WEB_CONCURRENCY=2`, `OLLAMA_URL`, `LLM_NAMING_MODEL`, `LLM_NAMING_VERIFY_MODEL`, `LLM_CHAT_MODEL`, `LLM_SYSTEM_PROMPT_MODEL`, `LLM_SYSTEM_PROMPT_VERIFY_MODEL`.
- Auto-deploy is enabled on pushes to `main`; monitor builds via the Render dashboard.

## Setup
- Prefer Docker for day-to-day work:
  - `docker build -t talingtrees:latest .`
  - `docker run -p 3000:3000 --name talingtrees talingtrees:latest`
  - When finished: `docker stop talingtrees` and `docker rm talingtrees`.
- Local setup (only when required):
  - Install dependencies with `bundle install`.
  - To work with local LLM models run `bundle exec rake ollama:setup`.
    - If Ollama is already installed, ensure the default model is present with `ollama pull gemma3:4b`.
  - Prepare the database with `bundle exec rails db:create` and `bundle exec rails db:migrate`.

## Data Tasks
Several Rake tasks exist to manage tree data:
- `bundle exec rake db:download_trees` – download raw data.
- `bundle exec rake db:import_trees[<count>]` – import the downloaded files; pass a number to limit trees (e.g. `db:import_trees[30]`).
- Ensure the Ollama model is available **before** running `db:name_trees` or `db:system_prompts`: `ollama pull gemma3:4b` (weights are not packaged in Docker).
- `bundle exec rake db:import_points_of_interest` – import the Victorian Heritage Register points.
- `bundle exec rake db:import_ptv_points_of_interest` – import PTV train, tram, bus, interstate, and SkyBus stops.
- `bundle exec rake db:name_trees` – assign names via the configured LLM.
- `bundle exec rake db:add_relationships` – generate tree relationships.
- `bundle exec rake db:system_prompts` – assign system prompts to trees.

These tasks clear and repopulate the tree records, so run them with care.

## Workflow Rules
- You may stage changes to share diffs, but never commit or push without explicit user approval.
- Do **not** mark TODO items as complete unless the user confirms the work is accepted.
- Follow this loop for every task: implement changes → stage as needed for review → present the work (tests, docs, screenshots) → wait for user approval → only then commit/push.
- When changes affect the Docker image or runtime environment, rebuild the image and restart the container before presenting results so reviewers see current behavior.
- Keep the Docker container in sync while iterating: rebuild after code or asset updates and verify features inside the running container so screenshots, manual QA, and test results reflect the shipping image. **Never copy individual files into the container manually; rebuild instead.**

## Development
- Groom and keep `readme.md`, `AGENTS.md`, and any other documentation up to date with your changes.
- Follow the workflow: implement changes, present them for user review, and only commit/push after approval.
- Treat all warnings as errors and address them or add them to the TODO list in `TODO.md`.
- Update `TODO.md` as tasks are completed or discovered.
- Document any unusual directories or files or variations from the Rails standard directory structure in the `readme.md`.
- Before considering a task complete:
  - Run `ruby test/run_tests.rb` and verify all tests pass.
  - Ensure RuboCop, bundler-audit, and Brakeman show no warnings or errors and treat all warnings as errors.
  - Confirm documentation has been updated.
- Update `TODO.md` and the changelog to record your work.

### Screenshots
- `ruby test/run_tests.rb` regenerates all reference screenshots under `screenshots/` each run. Always commit the updated images so visual baselines stay current.
- Inspect the auto-generated diff montages in `screenshots/diffs/` to understand visual changes before submitting work.
- Do **not** commit the comparison images in `screenshots/diffs/`; they are temporary review artifacts.

### Analytics
- Blazer dashboards live at `/blazer` and reuse the primary database connection. Access is restricted to admin users—be sure to keep admin authentication working when making changes to sessions or users.

## Testing
Run `ruby test/run_tests.rb` to execute the full test suite. This script also generates:
- RuboCop report (`rubocop_report.txt`)
- bundler-audit report (`bundler_audit_report.txt`)
- Brakeman report (`brakeman_report.txt`)
- Code coverage results (`coverage.txt`)

The CI workflow runs the same script and posts these reports to pull requests.

## Pull Requests
- Always report the results of all testing and qa.
- PR title should be "[Category] <short description>", where category is like "FIX", "DOCS", "FEATURE", ...

## Coding Style
- Ruby code is linted using RuboCop with the rules defined in `.rubocop.yml`.
- Keep line length under 140 characters unless it makes the code less readable.
- Avoid methods over 50 lines or with high complexity unless necessary.

## Miscellaneous
- Do not commit generated report files or `coverage.txt`; they are ignored via `.gitignore`.
- Use Rails conventions when creating models, controllers, and views.
- Refer to `readme.md` for full setup and deployment details.

## Best Practices
- Implement features so they are easily testable and covered by comprehensive tests.
- Code coverage must not decrease if overall coverage is below 75%; aim to improve it.
- When total coverage falls below 50% you should add new tests to raise it.
- Document code thoroughly so new developers can understand the system.
- Add unrelated issues found during development to `TODO.md`.
- If you find yourself making the same mistake more than once, you should update the documentation to reduce the chance of agents making the same mistake in the future.
