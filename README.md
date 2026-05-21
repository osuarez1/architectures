# Architectures

Public **documentation-only** repository. The git tree contains only:

| Path | Purpose |
|------|---------|
| **`README.md`** | This file — repo purpose and security rules |
| **`wiki/`** | Sanitized architecture (staging for [GitHub Wiki](wiki/README.md)); includes `publish.map` |
| **`bin/sync_wiki.sh`** | Optional publish helper → GitHub Wiki (see [wiki/README.md](wiki/README.md)) |
| **`candidates/`** | Local inbox for raw docs before sanitization — **only `.keep` is in git** |
| **`.gitignore`** | Keeps the repo minimal |

No application source, Docker, CI pipelines, or app runtime. `bin/sync_wiki.sh` is documentation publish tooling only. Runnable systems live in a private **application monorepo**.

## Quick start

1. Read [Security](#security) below before editing any wiki page.
2. Open [wiki/2026/reporting-ai-agent/ARCHITECTURE.md](wiki/2026/reporting-ai-agent/ARCHITECTURE.md) for canonical diagrams.
3. Publish to GitHub Wiki: [wiki/README.md](wiki/README.md).

## Documented systems

| Wiki path | Summary |
|-----------|---------|
| [wiki/2026/reporting-ai-agent/](wiki/2026/reporting-ai-agent/) | Reporting agent — architecture, chat flow, backend, frontend |
| [wiki/2025/subtitle-file-analyzer/](wiki/2025/subtitle-file-analyzer/) | Subtitle file analyzer — WebVTT → structured metadata |

## What belongs in `wiki/`

Structural pages only (Mermaid, responsibilities, logical flows)—see [CHAT_PROCESSING.md](wiki/2026/reporting-ai-agent/CHAT_PROCESSING.md) as the depth template.

- `ARCHITECTURE.md` — topology and deployment patterns
- `CHAT_PROCESSING.md` — routing, execution paths, streaming
- `backend.md` / `frontend.md` — component structure
- `README.md` — project index

## What does **not** belong in this repo

- Env tables, shell commands, `backend/…` / `frontend/…` source paths
- Secrets, hostnames, production bucket names, IAM JSON, admin destructive APIs
- **Committed** content under `candidates/` (anything except `candidates/.keep`)
- Extra files at repository root (use local editor config; see `.gitignore`)

---

## Candidates inbox

`candidates/` is where **raw** architecture write-ups are dropped (from the application monorepo, exports, or drafts) before they are **sanitized** and promoted into `wiki/`.

| | |
|--|--|
| **Git tracks** | `candidates/.keep` only — all other files under `candidates/` are ignored |
| **Purpose** | Hold sensitive or verbose source material locally while agents redact and restructure |
| **Output** | Public-safe pages under `wiki/YYYY/<project>/`, then [GitHub Wiki](wiki/README.md) |

### What agents should do when files appear in `candidates/`

1. **Do not commit** candidate files — they must not enter the public repository.
2. **Read** [Security](#security) and treat source material as **internal until redacted**.
3. **Redact** — remove secrets, hostnames, buckets, IAM detail, source paths, env tables, shell commands, file indexes, destructive admin APIs.
4. **Promote** into `wiki/YYYY/<project>/` using the structural layout:
   - `ARCHITECTURE.md`, project `README.md`, and optional `CHAT_PROCESSING.md`, `backend.md`, `frontend.md`
   - Depth and tone: [CHAT_PROCESSING.md](wiki/2026/reporting-ai-agent/CHAT_PROCESSING.md)
5. **Links** — [GitHub Wiki link rules](#github-wiki-links) only (`[[Page-Name]]`, full GitHub URLs).
6. **Register** — update [wiki/README.md](wiki/README.md) publish table, [wiki/Home.md](wiki/Home.md), and this README’s documented systems list.
7. **Commit** (if the user asked) — only changes under `wiki/` and `README.md`, e.g. `docs(wiki): add … architecture`.
8. **Cleanup** — ask the user whether to delete promoted files from `candidates/` or keep them locally.

Local agent detail: **CONVENTION.md**, **AGENTS.md**, **`.cursor/rules/candidates-sanitization.mdc`**.

---

## Security

All wiki content is **public**. Every page must be safe to publish on GitHub Wiki.

### Wiki page tiers

| Tier | Allowed |
|------|---------|
| **Structural** | Mermaid, component roles, logical API groups, generic dependencies |
| **Overview** | Index and links |
| **App monorepo only** | Env vars, commands, file paths, migrations, admin runbooks — **never paste here** |

### Forbidden

- API keys, tokens, passwords, `.env` values
- Hostnames, buckets, ARNs with account IDs
- Auth internals, privileged role names, schema/table dumps
- Source paths (`backend/app/…`), test lists, migration IDs
- Destructive admin API documentation

### Redaction pattern (when copying from the app monorepo)

1. Keep diagrams and responsibility tables.
2. Remove file paths and shell commands.
3. Replace env tables with “configured in application monorepo”.
4. Add a **Public-safe** banner on each wiki page.
5. Link using [GitHub Wiki link rules](#github-wiki-links) (flat wiki—never `../` paths).

### GitHub Wiki links

Staged `wiki/` files are copied to a **flat** GitHub Wiki (see [wiki/README.md](wiki/README.md)). Links must work **after publish**, not only in the git tree.

| Target | Correct | Wrong |
|--------|---------|--------|
| Another published wiki page | `[[2026-Reporting-AI-Agent-Architecture]]` | `../../ARCHITECTURE.md`, `[text](../foo.md)` |
| Wiki home | `[[Home]]` | `../../Home.md` |
| Repo README / security | `https://github.com/osuarez1/architectures/blob/main/README.md#security` | `../../../README.md#security` |
| Publish guide (git, not on wiki) | `https://github.com/osuarez1/architectures/blob/main/wiki/README.md` | `../../README.md` |

**Agents and editors:** when adding a wiki page, use the **GitHub Wiki page name** from `wiki/README.md` (e.g. `2026-Reporting-AI-Agent-Chat-Processing`), not the staging file path.

### Before publishing to GitHub Wiki

- [ ] Public-safe banner on each page
- [ ] No secrets, hosts, or source paths
- [ ] No env tables or command blocks
- [ ] Matches structural depth of [CHAT_PROCESSING.md](wiki/2026/reporting-ai-agent/CHAT_PROCESSING.md)
- [ ] All links follow [GitHub Wiki link rules](#github-wiki-links) (no relative `../` paths)

Publish steps: [wiki/README.md](wiki/README.md).

## Commits and pull requests

This repo uses **Conventional Commits** with a required **scope**. Prefer **`docs`** for wiki and README changes.

| Scope | Paths |
|-------|--------|
| `wiki` | `wiki/**` |
| `docs` | `README.md` |
| `chore` | `.gitignore` |

**Format:** `docs(wiki): imperative subject` — no trailing period; imperative mood (`add`, `fix`, not `added`).

**Split commits** when you change both `README.md` and `wiki/` in unrelated ways.

**PRs (GitHub):** target `main`; title matches commit style; body with Overview, Changes, Testing. Confirm [security](#security) and [wiki link](#github-wiki-links) checklists for wiki changes.

**Agents:** do not commit unless asked; no `Co-authored-by:` or assistant trailers. Full rules in local **CONVENTION.md** and **`.cursor/rules/agent-git-commits.mdc`** (not in git).

---

### Local development (optional, not in git)

You may keep local-only files at the repo root (e.g. `.cursor/`, `AGENTS.md`, `CONVENTION.md`). They are in `.gitignore` and are **not** pushed to GitHub.
