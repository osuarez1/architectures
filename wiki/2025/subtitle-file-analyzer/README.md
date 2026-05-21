# Subtitle file analyzer (2025)

> **Public-safe wiki** — structural documentation only. Security: [README § Security](https://github.com/osuarez1/architectures/blob/main/README.md#security).

Admin-triggered pipeline: default-language **WebVTT** subtitles → **generative API** → structured JSON metadata (plot, tags, beliefs), with async normalization into searchable attributes.

## Pages (this project)

| Page | Content |
|------|---------|
| [[2025-Subtitle-File-Analyzer-Architecture]] | **Canonical diagrams** — ingestion, generative call, cache, background normalization |

Git path: `wiki/2025/subtitle-file-analyzer/` · Publish: [wiki/README.md](https://github.com/osuarez1/architectures/blob/main/wiki/README.md) · Wiki index: [[Home]]

## Runnable code

Private **application monorepo** (source, credentials, object storage, admin routes)—not the architectures repository.
