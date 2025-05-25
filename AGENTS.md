# Project Guidance for Codex Agents

This repository contains a Rails 7 application built with Ruby 3.2.3. Follow these instructions when contributing with an AI agent.

## Setup
- Install dependencies with `bundle install`.
- To work with local LLM models run `bundle exec rake ollama:setup`.
- Prepare the database with `bundle exec rails db:create` and `bundle exec rails db:migrate`.

## Data Tasks
Several Rake tasks exist to manage tree data:
- `bundle exec rake db:download_trees` – download raw data.
- `bundle exec rake db:import_trees` – import the downloaded files.
- `bundle exec rake db:name_trees` – assign names via the configured LLM.
- `bundle exec rake db:add_relationships` – generate tree relationships.
- `bundle exec rake db:system_prompts` – assign system prompts to trees.

These tasks clear and repopulate the tree records, so run them with care.

## Development
- Keep `readme.md`, `AGENTS.md`, and any other documentation up to date with your changes.
- Update the TODO list in `readme.md` as tasks are completed or discovered.
- Before considering a task complete:
  - Run `ruby test/run_tests.rb` and verify all tests pass.
  - Ensure RuboCop, bundler-audit, and Brakeman show no new warnings.
  - Confirm documentation has been updated.


## Testing
Run `ruby test/run_tests.rb` to execute the full test suite. This script also generates:
- RuboCop report (`rubocop_report.txt`)
- bundler-audit report (`bundler_audit_report.txt`)
- Brakeman report (`brakeman_report.txt`)
- Code coverage results (`coverage.txt`)

The CI workflow runs the same script and posts these reports to pull requests.

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
- Add unrelated issues found during development to the TODO list.

