# Changelog

This log summarizes notable updates based on commit history and completed TODO items.

## 2025-06-12
- Raised RuboCop metric limits and cleaned up tests to remove inline disables
- Simplified CI workflow to rely on `test/run_tests.rb` for security and linting reports
- Simplified CI workflow to rely on `test/run_tests.rb` for security and linting reports
- Added workflow to build Docker image in CI

## 2025-06-09
- Installed Node.js 20 via NodeSource in Docker build to ensure corepack is available
- Documented Node.js requirement in README
- Enabled Yarn 4 via corepack in the Docker build and README instructions

## 2025-06-10
- Reverted to Yarn 1 to avoid lockfile modifications during Docker builds
- Updated Dockerfile and README accordingly

## 2025-06-07
- Switched Docker build to use `yarn install --immutable` for compatibility with Yarn 4
- Updated controller tests to exercise real application code

## 2025-06-06
- Installed Node dependencies and compiled Tailwind CSS during Docker build
- Compiled CSS in the entrypoint to ensure styles are available

## 2025-06-05
- Renamed `llm_sustem_prompt` column to `llm_system_prompt`

## 2025-05-26
- Documented requirement for `SECRET_KEY_BASE` in production
- Fixed various RuboCop warnings and updated configuration files

## 2025-06-03
- Increased duplicate name check radius to 100m

## 2025-06-04
- Added rating verification for system prompts

## 2025-06-05
- Added search box to filter the tree list

## 2025-06-06
- Fixed failing tests by cleaning up TreeRelationship stubs
- Lightweight ActiveRecord stub returns nil for unknown attributes

## 2025-06-02
- Added validation loop for system prompt generation

## 2025-06-01
- Removed system prompt assignment from the naming script

## 2025-05-28
- Added combined relation dropdown listing all known relations in chat title
- Updated title format to display counts as "Neighbors - Friends - Species"

## 2025-05-29
- Generated unique system prompts for each tree using an LLM

## 2025-05-30
- Added logging for system prompt generation
- Filtered <think> tags from generated system prompts

## 2025-05-31
- Added tree details to system prompt generation
- Included tree name in the generated prompt facts

## 2025-05-27
- Switched tree name verification to a rating system with configurable threshold
- Documented the rating scale and updated tests
- Added reasons for each rating example to the verification prompt

## 2025-05-26
- Added dark mode toggle with saved preference
- Fixed styling so dark mode actually changes the page theme

## 2025-05-25
- Internalized Tailwind CSS and cleaned configuration
- Improved streaming response handling and chat layout
- Added console logging for Ollama requests
- Fixed tree chat trigger issues and CSRF helper
- Expanded AGENTS guidelines and fixed config

## 2025-05-24
- Optimized tree list loading and memory usage
- Split tree import into download and import tasks
- Configured Puma single mode and updated deployment scripts
- Preloaded relationships and tags for better performance
- Added Docker setup and deployment documentation

## 2025-05-23
- Added Active Storage and production environment configs
- Created deployment workflow with Render CLI helpers
- Refined Dockerfile and deployment scripts

## 2025-05-22
- Ensured tree relationships are mutual
- Improved new tree highlight animations and relation lines
- Added hover dropdown for tree relations
- Fixed tree tagging bugs

## 2025-05-21
- Introduced tagging system for trees and users with live updates
- Displayed neighbor and friend counts in chat titles
- Added UI controls for tag selection and removal
- Reloaded chat when user tagged friendly

## 2025-05-20
- Added user location tracking with map marker
- Created relationship model between users and trees
- Added neighbor detection and highlighted radius on map
- Included tree details in verification prompts
- Added Brakeman and bundler-audit reports to CI

## 2025-05-19
- Set tree names blank on import and improved naming script
- Implemented verification steps for tree naming
- Added Tailwind styling for tree list page
- Introduced task to retry naming until valid

## 2025-05-18
- Created initial Rails app with tree and user tables
- Added map landing page and chat interface
- Integrated streaming chat with local Ollama LLM
- Added tasks to import and name trees with tests
- Set up CI with coverage reports and security checks
