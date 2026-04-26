# Development Rules

## Conversational Style

- Keep answers short and concise
- No emojis in commits, issues, PR comments, or code
- No fluff or cheerful filler text
- Technical prose only, be kind but direct (e.g., "Thanks @user" not "Thanks so much @user!")

## Code Quality

- No `any` types unless absolutely necessary
- Check node_modules for external API type definitions instead of guessing
- **NEVER use inline imports** - no `await import("./foo.js")`, no `import("pkg").Type` in type positions, no dynamic imports for types. Always use standard top-level imports.
- NEVER remove or downgrade code to fix type errors from outdated dependencies; upgrade the dependency instead
- Always ask before removing functionality or code that appears to be intentional
- Do not preserve backward compatibility unless the user explicitly asks for it
- Never hardcode key checks with, eg. `matchesKey(keyData, "ctrl+x")`. All keybindings must be configurable. Add default to matching object (`DEFAULT_EDITOR_KEYBINDINGS` or `DEFAULT_APP_KEYBINDINGS`)

## Commands

- After code changes (not documentation changes): `npm run check` (get full output, no tail). Fix all errors, warnings, and infos before committing.
- Note: `npm run check` does not run tests.
- NEVER run: `npm run dev`, `npm run build`, `npm test`
- Only run specific tests if user instructs: `npx tsx ../../node_modules/vitest/dist/cli.js --run test/specific.test.ts`
- Run tests from the package root, not the repo root.
- If you create or modify a test file, you MUST run that test file and iterate until it passes.
- When writing tests, run them, identify issues in either the test or implementation, and iterate until fixed.
- For `packages/coding-agent/test/suite/`, use `test/suite/harness.ts` plus the faux provider. Do not use real provider APIs, real API keys, or paid tokens.
- Put issue-specific regressions under `packages/coding-agent/test/suite/regressions/` and name them `<issue-number>-<short-slug>.test.ts`.
- NEVER commit unless user asks

## Contribution Gate

- New issues from new contributors are auto-closed by `.github/workflows/issue-gate.yml`
- New PRs from new contributors without PR rights are auto-closed by `.github/workflows/pr-gate.yml`
- Maintainer approval comments are handled by `.github/workflows/approve-contributor.yml`
- Maintainers review auto-closed issues daily
- Issues that do not meet the quality bar in `CONTRIBUTING.md` are not reopened and do not receive a reply
- `lgtmi` approves future issues
- `lgtm` approves future issues and rights to submit PRs

When creating issues:

- Add `pkg:*` labels to indicate which package(s) the issue affects
  - Available labels: `pkg:agent`, `pkg:ai`, `pkg:coding-agent`, `pkg:mom`, `pkg:pods`, `pkg:tui`, `pkg:web-ui`
- If an issue spans multiple packages, add all relevant labels

When posting issue/PR comments:

- Write the full comment to a temp file and use `gh issue comment --body-file` or `gh pr comment --body-file`
- Never pass multi-line markdown directly via `--body` in shell commands
- Preview the exact comment text before posting
- Post exactly one final comment unless the user explicitly asks for multiple comments
- If a comment is malformed, delete it immediately, then post one corrected comment
- Keep comments concise, technical, and in the user's tone

When closing issues via commit:

- Include `fixes #<number>` or `closes #<number>` in the commit message
- This automatically closes the issue when the commit is merged

## PR Workflow

- Analyze PRs without pulling locally first
- If the user approves: create a feature branch, pull PR, rebase on main, apply adjustments, commit, merge into main, push, close PR, and leave a comment in the user's tone
- You never open PRs yourself. We work in feature branches until everything is according to the user's requirements, then merge into main, and push.

## Testing pi Interactive Mode with tmux

To test pi's TUI in a controlled terminal environment:

```bash
# Create tmux session with specific dimensions
tmux new-session -d -s pi-test -x 80 -y 24

# Start pi from source
tmux send-keys -t pi-test "cd /Users/badlogic/workspaces/pi-mono && ./pi-test.sh" Enter

# Wait for startup, then capture output
sleep 3 && tmux capture-pane -t pi-test -p

# Send input
tmux send-keys -t pi-test "your prompt here" Enter

# Send special keys
tmux send-keys -t pi-test Escape
tmux send-keys -t pi-test C-o  # ctrl+o

# Cleanup
tmux kill-session -t pi-test
```

## Changelog

Location: `packages/*/CHANGELOG.md` (each package has its own)

### Format

Use these sections under `## [Unreleased]`:

- `### Breaking Changes` - API changes requiring migration
- `### Added` - New features
- `### Changed` - Changes to existing functionality
- `### Fixed` - Bug fixes
- `### Removed` - Removed features

### Rules

- Before adding entries, read the full `[Unreleased]` section to see which subsections already exist
- New entries ALWAYS go under `## [Unreleased]` section
- Append to existing subsections (e.g., `### Fixed`), do not create duplicates
- NEVER modify already-released version sections (e.g., `## [0.12.2]`)
- Each version section is immutable once released

### Attribution

- **Internal changes (from issues)**: `Fixed foo bar ([#123](https://github.com/badlogic/pi-mono/issues/123))`
- **External contributions**: `Added feature X ([#456](https://github.com/badlogic/pi-mono/pull/456) by [@username](https://github.com/username))`

## Adding a New LLM Provider (packages/ai)

Adding a new provider requires changes across multiple files:

### 1. Core Types (`packages/ai/src/types.ts`)

- Add API identifier to `Api` type union (e.g., `"bedrock-converse-stream"`)
- Create options interface extending `StreamOptions`
- Add mapping to `ApiOptionsMap`
- Add provider name to `KnownProvider` type union

### 2. Provider Implementation (`packages/ai/src/providers/`)

Create provider file exporting:

- `stream<Provider>()` function returning `AssistantMessageEventStream`
- `streamSimple<Provider>()` for `SimpleStreamOptions` mapping
- Provider-specific options interface
- Message/tool conversion functions
- Response parsing emitting standardized events (`text`, `tool_call`, `thinking`, `usage`, `stop`)

### 3. Provider Exports and Lazy Registration

- Add a package subpath export in `packages/ai/package.json` pointing at `./dist/providers/<provider>.js`
- Add `export type` re-exports in `packages/ai/src/index.ts` for provider option types that should remain available from the root entry
- Register the provider in `packages/ai/src/providers/register-builtins.ts` via lazy loader wrappers, do not statically import provider implementation modules there
- Add credential detection in `packages/ai/src/env-api-keys.ts`

### 4. Model Generation (`packages/ai/scripts/generate-models.ts`)

- Add logic to fetch/parse models from provider source
- Map to standardized `Model` interface

### 5. Tests (`packages/ai/test/`)

Add provider to: `stream.test.ts`, `tokens.test.ts`, `abort.test.ts`, `empty.test.ts`, `context-overflow.test.ts`, `image-limits.test.ts`, `unicode-surrogate.test.ts`, `tool-call-without-result.test.ts`, `image-tool-result.test.ts`, `total-tokens.test.ts`, `cross-provider-handoff.test.ts`.

For `cross-provider-handoff.test.ts`, add at least one provider/model pair. If the provider exposes multiple model families (for example GPT and Claude), add at least one pair per family.

For non-standard auth, create utility (e.g., `bedrock-utils.ts`) with credential detection.

### 6. Coding Agent (`packages/coding-agent/`)

- `src/core/model-resolver.ts`: Add default model ID to `DEFAULT_MODELS`
- `src/cli/args.ts`: Add env var documentation
- `README.md`: Add provider setup instructions

### 7. Documentation

- `packages/ai/README.md`: Add to providers table, document options/auth, add env vars
- `packages/ai/CHANGELOG.md`: Add entry under `## [Unreleased]`

## Releasing

**Lockstep versioning**: All packages always share the same version number. Every release updates all packages together.

**Version semantics** (no major releases):

- `patch`: Bug fixes and new features
- `minor`: API breaking changes

### Steps

1. **Update CHANGELOGs**: Ensure all changes since last release are documented in the `[Unreleased]` section of each affected package's CHANGELOG.md

2. **Run release script**:
   ```bash
   npm run release:patch    # Fixes and additions
   npm run release:minor    # API breaking changes
   ```

The script handles: version bump, CHANGELOG finalization, commit, tag, publish, and adding new `[Unreleased]` sections.

## Fork Customizations (do not overwrite)

This repository is a fork of `badlogic/pi-mono` (configured as `upstream`). Our copy is `bruno-arsi/pi-mono` (configured as `origin`). Upstream code is generally relevant and worth merging, **but our customizations are equally important and must not be silently overwritten** by any sync, rebase, cherry-pick, or merge.

**Sync direction is one-way: upstream → origin only.** We never push to `upstream` and we never open pull requests against `badlogic/pi-mono`. Our fork is a private downstream consumer; contributions back to upstream are out of scope. Any agent that thinks it should push to upstream, open a PR there, or otherwise propagate our changes back is wrong — stop and ask the user.

Any agent performing fork sync work (see `.claude/agents/repo-syncer.md`) MUST read this section first and respect every entry. If upstream changes a file listed here, the agent must surface the conflict to the user instead of accepting upstream's version.

### Removed entirely (must never be reintroduced)

We dropped Google/Gemini provider support and the `@google/genai` SDK. Reintroducing any of the following would silently undo that work:

- `packages/ai/src/providers/google.ts`, `google-vertex.ts`, `google-gemini-cli.ts`, `google-shared.ts`
- `packages/ai/src/utils/oauth/google-antigravity.ts`, `google-gemini-cli.ts`
- `packages/coding-agent/examples/extensions/antigravity-image-gen.ts`
- The `@google/genai` dependency in `packages/ai/package.json`
- Provider strings: `"google"`, `"google-vertex"`, `"google-gemini-cli"`, `"google-antigravity"`
- API strings: `"google-generative-ai"`, `"google-gemini-cli"`, `"google-vertex"`
- OAuth providers: `geminiCliOAuthProvider`, `antigravityOAuthProvider`
- Pure-Google test files: `packages/ai/test/google-*.test.ts`

If a cherry-pick or merge would recreate any of these, abort and ask the user.

### Excluded from upstream (never adopt)

Providers upstream introduced *after* the fork point that we deliberately do not pull in. They were never in our tree, and we want sync agents to skip any commit that adds them:

- `deepseek` provider (and any `packages/ai/src/providers/deepseek*.ts`, `KnownProvider`/`KnownApi` `"deepseek"` entries, `deepseek` envMap entry, default-model entries, docs sections, or test blocks). Skip cherry-picks whose primary purpose is adding/fixing DeepSeek. If a non-DeepSeek fix is bundled with DeepSeek changes in the same upstream commit, surface it to the user instead of silently dropping or partially applying it.

### Versioning policy (fork mirrors upstream tip)

All packages in this monorepo carry a version of the form `<upstream-version>-fork.<N>` (e.g. `0.70.2-fork.0`). The semver core (`<upstream-version>`) **must always match the latest upstream `Release vX.Y.Z` commit we have synced past**. The `-fork.N` prerelease tag marks our customizations on top of that upstream base.

Rules:

- We **never publish to npm** — these versions exist only locally and in our fork's `origin/main`.
- Upstream's `Release vX.Y.Z` and `Add [Unreleased] section for next cycle` commits are still **skipped** during sync (they touch CHANGELOG/release machinery we don't run). The repo-syncer agent must instead **manually rebump** every `package.json` version in the monorepo (the 7 main packages plus the example/extension packages under `packages/coding-agent/examples/extensions/*` and `packages/web-ui/example`) to `<upstream-tip-version>-fork.0` after the cherry-pick batch, run `node scripts/sync-versions.js` to keep inter-package deps in lockstep, and run `npm install` to refresh `package-lock.json`.
- If we make additional fork-only commits on top of the same upstream base, bump the suffix: `0.70.2-fork.0` → `0.70.2-fork.1`, etc.
- The "new version available" banner in `packages/coding-agent/src/modes/interactive/interactive-mode.ts` (`checkForNewVersion` + `isUpstreamNewer`) compares only `major.minor.patch` against upstream's npm `latest`. It deliberately ignores the `-fork.N` prerelease tag so the banner only fires when upstream actually advances past our base. Do not revert that fork-aware comparison during sync — upstream has only the naive `latest !== this.version` check.

### Modified (changes must survive any sync)

- `packages/ai/src/types.ts` — `KnownApi` and `KnownProvider` unions have all Google entries removed. The `thoughtSignature` comment on `ToolCall` was rephrased to remove the "Google-specific" wording (it is used by `openai-completions` for `reasoning.encrypted` payloads).
- `packages/ai/src/index.ts` — Google provider option type re-exports removed.
- `packages/ai/src/env-api-keys.ts` — Vertex ADC detection block, dynamic node:fs/os/path imports for it, and the `google` entry in `envMap` are gone.
- `packages/ai/src/providers/register-builtins.ts` — Google provider module interfaces, lazy loaders, exports, and `registerApiProvider` calls removed.
- `packages/ai/src/utils/oauth/index.ts` — Google OAuth re-exports and registry entries removed.
- `packages/ai/package.json` — `./google`, `./google-gemini-cli`, `./google-vertex` subpath exports removed; `@google/genai` dropped from `dependencies`; `gemini` removed from `keywords`; `canvas` removed from `devDependencies`.
- `packages/ai/scripts/generate-models.ts` — Google sections excluded (data.google block, opencode `@ai-sdk/google` branch skipped via `continue`, antigravity `contextWindow` override, manual `gemini-3.1-flash-lite-preview` add, `cloudCodeAssistModels`, `antigravityModels`, `vertexModels` blocks). The OpenCode comment explicitly says Google entries are skipped.
- `packages/ai/src/models.generated.ts` — Regenerated without any `provider: "google*"` or `api: "google-*"` entries. Gemini-named models served via *other* providers (vercel-ai-gateway, openrouter, github-copilot, opencode) are kept because they use other APIs.
- `packages/ai/test/*` — Pure-Google test files were deleted; cross-provider tests had Google blocks removed but kept Gemini-via-other-provider blocks.
- `packages/ai/README.md` — Google/Vertex/Gemini OAuth sections removed.
- `packages/coding-agent/src/cli/args.ts:209` — Default provider in `--help` is `anthropic` (was `google`).
- `packages/coding-agent/src/core/model-resolver.ts` — `defaultModelPerProvider` no longer has `google`, `google-gemini-cli`, `google-antigravity`, `google-vertex` entries.
- `packages/coding-agent/test/{utilities,compaction-thinking-model,model-registry,auth-storage,args}.test.ts` — Google references removed; antigravity describe block in compaction test deleted.
- `packages/coding-agent/docs/{models,custom-provider,providers,extensions,settings,rpc}.md` — Google sections and table rows removed.
- Removed `packages/ai/scripts/generate-test-image.ts` (the `canvas` test fixture generator). The fixture `packages/ai/test/data/red-circle.png` is now committed instead of generated.

### Added (local-only, do not push to upstream)

- `rebuild-and-install-pi.sh` — Local rebuild + global install script.
- `.claude/agents/repo-syncer.md` — This fork's sync agent.

### Test-mock fixes (kept in sync with current production code)

These fixes update test scaffolding that drifted from production. They are kept in our fork; if upstream applies similar fixes the cherry-pick may conflict — resolve preserving our version unless upstream's fix is materially different:

- `packages/coding-agent/test/print-mode.test.ts` — `setRebindSession: vi.fn()` added to `FakeRuntimeHost` (type + factory).
- `packages/coding-agent/test/rpc-prompt-response-semantics.test.ts` — `setRebindSession: vi.fn()` added to runtimeHost mock.
- `packages/coding-agent/test/agent-session-concurrent.test.ts` — `invalidate: () => {}` added to both `_extensionRunner` stubs (type + value).
- `packages/coding-agent/test/interactive-mode-compaction.test.ts` — `terminal: { setProgress: vi.fn() }` added to the `ui` mock.
- `packages/coding-agent/test/interactive-mode-clone-command.test.ts` — `handleRuntimeSessionChange` removed from `CloneCommandContext` and assertion (production no longer calls it).
- `packages/ai/test/openai-completions-tool-choice.test.ts` — Four zai tests removed because they referenced model IDs (`glm-5`, `glm-4.7-flash`, `glm-4.6v`) that no longer exist in the regenerated `models.generated.ts` (upstream catalog drift).

### Reasoning summary

The fork removed Google support to drop the `@google/genai` SDK and its transitive deps (specifically the `node-domexception` deprecation chain via `gaxios` → `node-fetch@3` → `fetch-blob`). Anything that brings the Google providers back also brings that dep chain back, defeating the purpose of the fork. Treat this as a hard invariant.

## **CRITICAL** Git Rules for Parallel Agents **CRITICAL**

Multiple agents may work on different files in the same worktree simultaneously. You MUST follow these rules:

### Committing

- **ONLY commit files YOU changed in THIS session**
- ALWAYS include `fixes #<number>` or `closes #<number>` in the commit message when there is a related issue or PR
- NEVER use `git add -A` or `git add .` - these sweep up changes from other agents
- ALWAYS use `git add <specific-file-paths>` listing only files you modified
- Before committing, run `git status` and verify you are only staging YOUR files
- Track which files you created/modified/deleted during the session

### Forbidden Git Operations

These commands can destroy other agents' work:

- `git reset --hard` - destroys uncommitted changes
- `git checkout .` - destroys uncommitted changes
- `git clean -fd` - deletes untracked files
- `git stash` - stashes ALL changes including other agents' work
- `git add -A` / `git add .` - stages other agents' uncommitted work
- `git commit --no-verify` - bypasses required checks and is never allowed

### Safe Workflow

```bash
# 1. Check status first
git status

# 2. Add ONLY your specific files
git add packages/ai/src/providers/transform-messages.ts
git add packages/ai/CHANGELOG.md

# 3. Commit
git commit -m "fix(ai): description"

# 4. Push (pull --rebase if needed, but NEVER reset/checkout)
git pull --rebase && git push
```

### If Rebase Conflicts Occur

- Resolve conflicts in YOUR files only
- If conflict is in a file you didn't modify, abort and ask the user
- NEVER force push

### User override

If the user instructions conflict with rules set out here, ask for confirmation that they want to override the rules. Only then execute their instructions.
