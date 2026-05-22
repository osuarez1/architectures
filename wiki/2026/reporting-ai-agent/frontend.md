# Reporting AI Agent — Frontend (2026)

> Publish to GitHub Wiki as **2026-Reporting-AI-Agent-Frontend** (flat page name).  
> **Public-safe overview** — structure only. Security: [README § Security](https://github.com/osuarez1/architectures/blob/main/README.md#security). Implementation paths live in the private application monorepo.

Diagrams: [[2026-Reporting-AI-Agent-Architecture]] · Chat flow: [[2026-Reporting-AI-Agent-Chat-Processing]]

**Next.js** UI for the reporting agent. The browser uses **server-side proxy routes** (BFF), not the API origin directly, for privileged flows.

## Responsibilities

| Concern | Behavior |
|---------|----------|
| UI | Chat, sessions, admin screens, and **filtered cohort form** (confirm step, matrix fullscreen/zoom, drill-down drawer) in the chat composer |
| BFF | Forwards authenticated requests to the backend |
| Auth | Session from the main portal; sensitive calls avoid exposing backend URLs to the client |

## Stack (logical)

Next.js App Router with server route handlers for proxying. No Redis or warehouse client in the browser or frontend server process.

## Client integration (conceptual)

| Concern | Behavior |
|---------|----------|
| Streaming | Parses server-sent events for steps, usage, and completion |
| Audit | Optional processing timeline for agent turns (routing + phases) |

## Where to read more

| Topic | Location |
|-------|----------|
| System topology | [[2026-Reporting-AI-Agent-Architecture]] |
| Chat routing and SSE | [[2026-Reporting-AI-Agent-Chat-Processing]] |
| Backend | [[2026-Reporting-AI-Agent-Backend]] |
| Source code and build | Private **application monorepo** |
