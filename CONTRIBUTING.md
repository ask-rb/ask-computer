# Contributing to ask-computer

## Development Setup

```bash
git clone <repo-url> && cd ask-rb/ask-computer
bundle install
```

Sibling gems (ask-core, ask-tools, etc.) are loaded from their local `lib/` directories
in the monorepo during development. The `test_helper.rb` handles this via `$LOAD_PATH`.

## Running Tests

```bash
bundle exec rake test
bundle exec ruby -Ilib -Itest test/foo_test.rb
bundle exec rake test TESTOPTS="--verbose"
```

## Code Style

- Use `# frozen_string_literal: true` in all Ruby files
- Follow the existing ask-rb gem conventions (see ask-github, ask-tools)
- Keep history handling permission-gated and metadata-only — never expose encrypted chunks or keys
