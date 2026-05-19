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

| Staged file | GitHub Wiki page |
|-------------|------------------|
| `wiki/Home.md` | Home |
| `wiki/2026/reporting-ai-agent/README.md` | 2026-Reporting-AI-Agent |
| `wiki/2026/reporting-ai-agent/ARCHITECTURE.md` | 2026-Reporting-AI-Agent-Architecture |
| `wiki/2026/reporting-ai-agent/CHAT_PROCESSING.md` | 2026-Reporting-AI-Agent-Chat-Processing |
| `wiki/2026/reporting-ai-agent/backend.md` | 2026-Reporting-AI-Agent-Backend |
| `wiki/2026/reporting-ai-agent/frontend.md` | 2026-Reporting-AI-Agent-Frontend |

```bash
git clone https://github.com/osuarez1/architectures.wiki.git
cd architectures.wiki

cp ../architectures/wiki/Home.md ./Home.md
cp ../architectures/wiki/2026/reporting-ai-agent/README.md ./2026-Reporting-AI-Agent.md
cp ../architectures/wiki/2026/reporting-ai-agent/ARCHITECTURE.md ./2026-Reporting-AI-Agent-Architecture.md
cp ../architectures/wiki/2026/reporting-ai-agent/CHAT_PROCESSING.md ./2026-Reporting-AI-Agent-Chat-Processing.md
cp ../architectures/wiki/2026/reporting-ai-agent/backend.md ./2026-Reporting-AI-Agent-Backend.md
cp ../architectures/wiki/2026/reporting-ai-agent/frontend.md ./2026-Reporting-AI-Agent-Frontend.md

git add .
git commit -m "Sync wiki from architectures repo"
git push
```

Do **not** copy this file to GitHub Wiki.

## Adding a new system

1. Create `wiki/YYYY/<project>/` with structural pages per [README.md § Security](https://github.com/osuarez1/architectures/blob/main/README.md#security).
2. Add rows to the table above and links in `wiki/Home.md`.
3. Update root `README.md` documented systems list.

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

**New page:** add a row to the publish table, then link with `[[That-Exact-Page-Name]]` everywhere.

## Do not

- Paste app monorepo runbooks without redaction.
- Add tracked files at the repository root (only `README.md`, `wiki/`, `.gitignore`).
