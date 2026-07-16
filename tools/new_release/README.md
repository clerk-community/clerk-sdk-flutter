# new_release

Release automation tool for the Clerk Flutter SDK monorepo. Handles version bumping, changelog generation, and publishing for `clerk_auth`, `clerk_backend_api`, and `clerk_flutter` in a single command.

## End-to-end flow

```
# ── On a release branch ──────────────────────────────────────────────────

# Bump patch, keep the -beta suffix
melos run new_release -- patch --pre=beta   # 0.0.16-beta → 0.0.17-beta

# Or graduate to a stable release (drop beta, bump minor)
melos run new_release -- minor              # 0.0.17-beta → 0.1.0

# Review the generated diff, then open a PR
git diff HEAD~1
git push origin release/0.0.17-beta

# ── On main, after the PR is merged ──────────────────────────────────────

git checkout main && git pull
melos run tag   # creates 4 tags and pushes → triggers pub.dev publish workflow
```

## Scripts

### `melos run new_release -- <bump-type> [--pre=<id>]`

Runs `bin/new_release.dart`. For each managed package it:

1. Bumps `version:` in `pubspec.yaml` using the semver rule below
2. Syncs `pubVersion` in `openapi_generator/openapi-generator-config.json`
3. Regenerates `packages/clerk_auth/lib/src/_version.dart` via `build_runner`
4. Prepends a new `## <version>` section to `CHANGELOG.md` from `git log` since the last per-package tag
5. Stages all modified files and commits `chore: release v<version>`

**Bump types:**

| Command | Example result |
|---|---|
| `patch --pre=beta` | `0.0.16-beta → 0.0.17-beta` |
| `patch` | `0.0.17-beta → 0.0.18` |
| `minor` | `0.0.17-beta → 0.1.0` |
| `major` | `0.0.17-beta → 1.0.0` |

The `--pre` flag appends a pre-release suffix after the bump. Omitting it graduates the release to stable.

### `melos run tag`

Runs `bin/tag.dart`. Must be executed on `main` after the release PR is merged — running it on a feature/release branch risks creating tags that point to orphaned commits after a squash-merge.

Creates four annotated tags on `HEAD` and pushes them all:

```
clerk_auth-v0.0.17-beta
clerk_backend_api-v0.0.17-beta
clerk_flutter-v0.0.17-beta
v0.0.17-beta          ← global tag, triggers the pub.dev publish workflow
```

## GitHub Actions publish workflow

`.github/workflows/publish.yaml` triggers on any `v*` tag push. It publishes packages to pub.dev in dependency order (`clerk_backend_api` → `clerk_auth` → `clerk_flutter`) and creates a GitHub Release. A 120-second wait is inserted between `clerk_auth` and `clerk_flutter` to allow pub.dev to propagate the newly published version.

The workflow uses OIDC-based publishing — no stored pub.dev credentials are required. Two things must be configured once:

| What | How |
|---|---|
| **pub.dev trusted publisher** | In the pub.dev package admin page, add a GitHub Actions trusted publisher pointing at this repo with environment `pub.dev` |
| **GitHub Actions environment** | In the repo Settings → Environments, create an environment named `pub.dev` (optionally add required reviewers for extra protection) |
| `GITHUB_TOKEN` | Automatically provided by GitHub Actions — no setup required |

## Changelog format

Entries use lowercase conventional-commit prefixes with a `[#N]` PR/issue reference rendered as a GitHub link:

```
## 0.0.17-beta

* feat(clerk_auth): add passkey improvements [[#420]](https://github.com/clerk-community/clerk-sdk-flutter/issues/420)
* fix: handle offline token refresh [[#421]](https://github.com/clerk-community/clerk-sdk-flutter/issues/421)
```

Commits that follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, etc.) keep their type and optional scope. Other commits are included as plain bullets. Only commits that touch each package's directory are included in that package's changelog.
