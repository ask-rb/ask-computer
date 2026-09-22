# Versioning — ask-computer

This file is the repository's **canonical versioning and release policy** for
`ask-computer`. If any other document (README, commit messages, notes)
disagrees with this file, this file wins.

## Semantic Versioning

Versions are `MAJOR.MINOR.PATCH`, following
[Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** — incompatible API changes
- **MINOR** — backward-compatible functionality added
- **PATCH** — backward-compatible bug fixes only

### Pre-1.0 (0.y.z)

While the major version is `0`, the public API is not yet declared stable:

- **PATCH** (`0.y.Z` → `0.y.Z+1`): backward-compatible bug fixes only. No
  public API additions or changes.
- **MINOR** (`0.y.z` → `0.(y+1).0`): new functionality; may also carry
  fixes. Any change that would be breaking after 1.0 is released as a
  pre-1.0 MINOR, never as a PATCH.
- **MAJOR**: reserved. `1.0.0` declares the public API stable; after that,
  breaking changes require a MAJOR bump.

### Sequential one-step increments

Every release advances exactly one step in the component that changed — a
patch release moves the patch number by exactly one. Never jump over
numbers (`0.1.3` → `0.1.8` is wrong), never skip a minor, and never reuse
a version that has already been published.

## Release tooling

- All `ask-*` gems and `yamine` release exclusively through **gemchain**
  (`gemchain update ask-computer <ver>` from the workspace root). Never
  hand-edit the version, hand-run `gem build`/`gem push`, or use
  `rake release`.
- **gemchain itself** is released manually — the cascade cannot release it —
  following exactly the same discipline: bump version, update changelog, run
  tests, commit, `gem build` + `gem push`, `git tag`, push, then
  `gem install gemchain` to refresh the binary.

## Release invariants

- **Clean tree required.** `git status` must show nothing before a release
  starts; the release's own changes (version, changelog, gemspec
  constraints) are committed as part of the release.
- **Everything must agree.** The published RubyGems version, the version in
  `lib/ask/computer/version.rb`, the `vX.Y.Z` git tag, and the source at
  that tag are all the same number. A release is not done until it is
  published, committed, tagged, and pushed.
- **Dependency releases use the gemchain cascade.** When a dependency of
  `ask-computer` (e.g. `ask-core`, `ask-tools`, `ask-mcp`) ships, gemchain's
  cascade performs the dependent release in order: rewrite the gemspec
  constraint → test → bump → commit → build → publish → tag → push. Never
  release dependents by hand.

## Unreleased changelog workflow

`CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/).
Every user-facing change is committed under an `## [Unreleased]` section as
it lands. At release time that section is renamed to the new version and
date, and a fresh empty `## [Unreleased]` is started above it:

```markdown
## [Unreleased]

## [0.1.4] - 2026-09-22

### Fixed
...
```

## Release checklist

1. **Clean tree** — `git status` shows nothing.
2. **Tests** — `bundle exec rake test` passes.
3. **Build** — `bundle exec rake build` succeeds.
4. **Changelog** — `[Unreleased]` renamed to `X.Y.Z` with today's date; a
   new empty `[Unreleased]` section added above it.
5. **Commit** — version and changelog committed (gemchain performs this
   step for `ask-*` gems).
6. **Tag** — `vX.Y.Z` created on the release commit.
7. **Publish** — the built gem pushed to RubyGems (via gemchain).
8. **Push** — commits and tags pushed to origin.
9. **Verify** — RubyGems, `lib/ask/computer/version.rb`, the tag, and the
   pushed source all report `X.Y.Z`.

## Examples

- Bug fix in `0.1.3` → release `0.1.4` (PATCH, one step).
- New functionality in `0.1.4` → release `0.2.0` (MINOR; a pre-1.0
  breaking change also goes here).
- Never `0.1.3` → `0.1.8`; the patch number moves by exactly one per
  release.
- Dependency cascade: `ask-core` ships `0.13.0`; from the workspace root run
  `gemchain update ask-core 0.13.0` — gemchain rewrites this gem's
  constraint, runs its tests, and releases the next `ask-computer` patch. No
  hand edits.
