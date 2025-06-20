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
- Groom and keep `readme.md`, `AGENTS.md`, and any other documentation up to date with your changes.
- Treat all warnings as errors and address them or add them to the TODO list.
- Update the TODO list in `readme.md` as tasks are completed or discovered.
- Document any unusual directories or files or variations from the Rails standard directory structure in the `readme.md`.
- Before considering a task complete:
  - Run `ruby test/run_tests.rb` and verify all tests pass.
  - Ensure RuboCop, bundler-audit, and Brakeman show no warnings or errors and treat all warnings as errors.
  - Confirm documentation has been updated.
  - Update the todo list and changlog to record your work.

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
- Add unrelated issues found during development to the TODO list.
- If you find yourself making the same mistake more than once, you should update the documentation to reduce the chance of agents making the same mistake in the future.
