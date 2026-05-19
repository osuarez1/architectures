# Wiki staging (publish to GitHub Wiki)

Markdown under `wiki/` is copied to the repository **Wiki** on GitHub. The git repo root keeps only `README.md`, `wiki/`, and `.gitignore`.

## Security before publish

Every page must follow [README.md § Security](https://github.com/osuarez1/architectures/blob/main/README.md#security):

- [ ] **Public-safe** banner (see `2026/reporting-ai-agent/` pages)
- [ ] Structural only — no env tables, commands, or source paths
- [ ] No secrets, hosts, buckets, or schema IDs
- [ ] Depth matches [CHAT_PROCESSING.md](2026/reporting-ai-agent/CHAT_PROCESSING.md)
- [ ] No relative links (`grep -r '](\.\./' wiki/` except this file → empty)

## Publish mapping (flat wiki page names)

**Canonical machine list:** [`wiki/publish.map`](publish.map) — keep this table in sync (one row per map line).

| Staged file | GitHub Wiki page |
|-------------|------------------|
| `wiki/Home.md` | Home |
| `wiki/2026/reporting-ai-agent/README.md` | 2026-Reporting-AI-Agent |
| `wiki/2026/reporting-ai-agent/ARCHITECTURE.md` | 2026-Reporting-AI-Agent-Architecture |
| `wiki/2026/reporting-ai-agent/CHAT_PROCESSING.md` | 2026-Reporting-AI-Agent-Chat-Processing |
| `wiki/2026/reporting-ai-agent/backend.md` | 2026-Reporting-AI-Agent-Backend |
| `wiki/2026/reporting-ai-agent/frontend.md` | 2026-Reporting-AI-Agent-Frontend |

### Publish (script)

From the repository root (after the [security checklist](#security-before-publish)):

```bash
chmod +x bin/sync_wiki.sh   # once
bin/sync_wiki.sh --check    # link grep + map/table parity only
bin/sync_wiki.sh --dry-run  # copy to .wiki-publish; no push
bin/sync_wiki.sh            # copy, commit, push to GitHub Wiki
```

The script reads `wiki/publish.map`, clones or updates `.wiki-publish/`, strips blockquote lines that start with `> Publish to GitHub Wiki` (editor-only flat-name hint; **Public-safe** banners stay), and commits to **architectures.wiki** with **Conventional Commits** (`docs(wiki): sync …`) — no `Co-authored-by:` or `Trello-Card:` trailers. Override message: `WIKI_COMMIT_MSG='docs(wiki): sync Home' bin/sync_wiki.sh`.

Do **not** copy this `wiki/README.md` file to GitHub Wiki.

### Agents and assistants

| Step | Action |
|------|--------|
| **When** | Run `bin/sync_wiki.sh` only if the user **explicitly** asked to publish to GitHub Wiki in this turn. |
| **Before sync** | Security checklist above; `bin/sync_wiki.sh --check` must pass. |
| **This repo (staging)** | Commit with `docs(wiki): …` when the user asked — scope `wiki` for `wiki/**`, per [README § Commits](https://github.com/osuarez1/architectures/blob/main/README.md#commits-and-pull-requests). |
| **Wiki repo (publish)** | Script default: `docs(wiki): sync …`; subject must stay `docs(wiki):`. |
| **New page** | Add a line to `wiki/publish.map`, a row to the table above, `[[Page-Name]]` links, and [wiki/Home.md](Home.md). |

## Adding a new system

1. Create `wiki/YYYY/<project>/` with structural pages per [README.md § Security](https://github.com/osuarez1/architectures/blob/main/README.md#security).
2. Add a line to [`wiki/publish.map`](publish.map), a row to the publish table above, and links in `wiki/Home.md`.
3. Update root `README.md` documented systems list.
4. Run `bin/sync_wiki.sh --check` before the first publish.

## Link conventions (required for every edit)

GitHub Wiki pages are **flat**. Staging lives under `wiki/2026/.../` but published URLs do **not**—links must use wiki page names or full GitHub URLs.

**Never** in files that get copied to the wiki (all of `wiki/` except this `wiki/README.md`):

- `../`, `../../`, `../../../`
- Markdown links to `.md` paths (`[text](../../Home.md)`, `[security](../../../README.md#security)`)

| Target | Use |
|--------|-----|
| Another wiki page | `[[GitHub-Wiki-Page-Name]]` from the table above (e.g. `[[2026-Reporting-AI-Agent-Architecture]]`) |
| Wiki home | `[[Home]]` |
| Repo README / security | `https://github.com/osuarez1/architectures/blob/main/README.md#security` |
| This publish guide (git only, not on wiki) | `https://github.com/osuarez1/architectures/blob/main/wiki/README.md` |

**New page:** add a line to `wiki/publish.map` and a row to the publish table, then link with `[[That-Exact-Page-Name]]` everywhere.

## Do not

- Paste app monorepo runbooks without redaction.
- Add tracked files at the repository root (only `README.md`, `wiki/`, `.gitignore`).
