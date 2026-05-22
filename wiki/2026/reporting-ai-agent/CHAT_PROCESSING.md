# Chat processing: question → response

> Publish to GitHub Wiki as **2026-Reporting-AI-Agent-Chat-Processing** (flat page name).  
> **Public-safe** — logical flow only. Security: [README § Security](https://github.com/osuarez1/architectures/blob/main/README.md#security). Implementation lives in the private application monorepo.

How a user message becomes an assistant reply: routing, execution paths, streaming, and persistence at a **structural** level.

Related diagrams: [[2026-Reporting-AI-Agent-Architecture]] (runtime and deploy patterns).

---

## End-to-end flow

```mermaid
sequenceDiagram
  participant U as User
  participant FE as Next.js UI
  participant PX as BFF proxy
  participant API as Chat stream API
  participant RT as Turn routing
  participant EX as Execution path
  participant DB as PostgreSQL

  U->>FE: Send message
  FE->>PX: POST chat stream
  PX->>API: Authenticated request
  API->>API: Load recent session context
  API-->>FE: SSE — received / context
  API->>RT: Classify turn
  RT-->>API: Route decision
  alt discovery
    API->>EX: Capability overview reply
  else chitchat
    API->>EX: Lightweight social reply
  else clarify
    API->>EX: Clarifying question
  else analytics
    API->>EX: Agent graph (tools + visualization)
  end
  EX-->>API: Reply + processing steps
  API-->>FE: SSE — steps, usage, complete
  API->>DB: Persist interaction
  FE-->>U: Text, chart, audit UI
```

**Rules of thumb**

- The browser uses the **BFF proxy**, not the API origin directly.
- Routing runs **before** the heavy agent path to avoid unnecessary LLM/graph work on social or meta questions.

---

## Pre-routing (every turn)

| Stage | Purpose |
|-------|---------|
| Auth & limits | Validate session; apply rate limits |
| History | Load recent turns from PostgreSQL (bounded window) |
| Uploads | Normalize attachments when present |
| Immediate SSE | Acknowledge receipt; emit “loading context” |
| Context build | Token-budgeted conversation history + session flags |
| Route | Choose execution path (see below) |
| User preferences | Overrides for deep analysis, large exports, audit queries, and chart analysis suppression when entering analytics |

---

## Turn routing (conceptual)

Routing is **ordered**: first match wins. Optional second tier (LLM classifier) applies only when the fast rules are ambiguous.

| Priority | Signal (conceptual) | Path | `turn_route` |
|----------|---------------------|------|--------------|
| 1 | “What can I ask?” / catalog-style | Discovery | `discovery` |
| 2 | Social / short acknowledgment | Chitchat | `chitchat` |
| 3 | Data, SQL, charts, session follow-ups | Analytics | `analytics` |
| 4 | Ambiguous + classifier enabled | Classifier → chitchat, clarify, or analytics | varies |
| 5 | Ambiguous + classifier off | Default to analytics | `ambiguous` → analytics |

**Session awareness:** Short follow-ups (e.g. “why?”, ≤ ~80 chars) after a prior chart/SQL turn stay on **analytics**, not chitchat. Prior analytics is detected when any earlier turn in the session had SQL, chart data, or a non–fast-path route (excluding prior discovery/chitchat).

**Discovery vs analytics:** Catalog phrasing (“what can I ask”, “what data is available”) routes to discovery; execution-style wording (metrics, charts, date ranges) forces analytics even when ambiguous.

**Chitchat gate:** Social/ack messages only when short (≤ ~220 chars), no data/discovery regex hit, and (with uploads) only explicit social patterns—not vague short questions.

**Classifier (optional):** When fast rules return ambiguous, a second-tier LLM may route to chitchat, clarify, or analytics. Discovery/capability questions must not be classified as chitchat.

| Setting (conceptual) | Default | Effect |
|----------------------|---------|--------|
| Turn classifier | off | LLM tier for ambiguous messages |
| Turn planner | off | Optional plan step before agent |
| Classifier confidence | ~0.72 | Cutoff for classifier routing |

Feature flags are configured in the **application monorepo**, not duplicated here.

---

## Execution paths

### 1. Discovery

Single LLM call, no tools, no warehouse query. Answers what the assistant can help with. Skips embedding storage for the turn.

### 2. Lightweight chitchat

Single LLM call for social or brief replies. Skips embeddings. May nudge users toward data questions when appropriate.

### 3. Early clarify

Fixed or classifier-generated clarifying question; **no** agent graph.

### 4. Full analytics (LangGraph)

Default for data questions. Planner (optional) → reasoning agent with tools → visualization.

```mermaid
flowchart LR
  plan[Plan optional] --> agent[Reasoning agent]
  agent -->|needs data| tools[Tools\nwarehouse / dictionary / uploads]
  agent -->|no tools| endNode[END]
  tools -->|error| agent
  tools -->|success| viz[Visualizer]
  viz --> endNode
```

| Node | Role |
|------|------|
| **Plan** | Optional turn plan (feature-flagged) |
| **Agent** | LLM with tools; SQL over parquet lake |
| **Tools** | Query lake, lookups, uploads |
| **Visualizer** | Chart/KPI component for the UI |

**Post-graph (conceptual):** Optional large exports to object storage; chart type chosen from result shape and user intent; presigned links for embeddable HTML when needed. Large query results may use object-storage CSV with iframe embeds; native heatmaps are used only when row shape fits UI limits.

#### Chart disambiguation

When the user **explicitly** requests a chart type the result set cannot support, the stream returns a **disambiguation** payload (no substitute chart). The user picks an option; the follow-up turn reuses **raw data** from the prior analytics turn rather than re-querying from scratch.

---

## Processing steps (user-visible)

The stream emits **phases** the UI can show in an activity panel and audit modal:

| Phase | Typical meaning |
|-------|-----------------|
| `receive` | Question accepted |
| `context` | History and session flags ready |
| `route` | Routing (and optional classifier) done |
| `classify` | Fast path (chitchat / discovery / clarify) |
| `plan` | Analytics plan (if enabled) |
| `sql` | Reasoning / query phase (analytics) |
| `reason` | Sub-steps under SQL (memory, model call, validation) |
| `tool` | Tool execution |
| `viz` | Formatting chart or table for UI |
| `artifact` | Downloads / embed URLs |

Nested **reason** substeps group under **sql** in the audit UI during analytics turns (live panel and audit modal).

| Substep (conceptual) | Purpose |
|----------------------|---------|
| `memory` | Load semantic lessons / past successes |
| `llm` | Primary reasoning model call |
| `sql_correction` | Retry when model emits SQL outside tools |
| `validate` | Syntax check per warehouse query |
| `validation_retry` | Second model pass after validation failure |

Labels may include attempt numbers when the graph loops agent → tools → agent after errors.

---

## Streaming contract (client)

Server-sent events carry structured progress and a final payload:

| Event | Purpose |
|-------|---------|
| `status` | Short human-readable status |
| `step` | Structured processing step (id, phase, label, timing) |
| `usage_progress` | Token / embedding totals |
| `complete` | Final text, chart payload, steps, routing metadata |
| `interaction_saved` | Persisted turn id |
| `error` | Terminal failure |

The Next.js client parses SSE and drives the chat UI plus optional **processing audit** for agent turns.

---

## Persistence (conceptual)

Each turn is stored in PostgreSQL:

| Stored | Notes |
|--------|--------|
| User question | Plain text |
| Assistant payload | JSON: reply, optional chart, processing steps, route metadata |
| SQL | When analytics ran a query |
| Embeddings | For analytics turns; skipped for chitchat/discovery |
| Usage | Token counts for billing/limits |

History APIs return enough metadata to reload charts (refreshing object-storage links when needed) and show past routing/steps.

---

## Semantic memory (high level)

Optional **lessons** and past successes can be retrieved by embedding similarity and injected into the analytics agent context. Curated and auto-suggested lessons are **inactive until approved** in admin flows. Details and retention policies are configured in the application monorepo—not duplicated here.

---

## Session lifecycle (high level)

| Concern | Behavior |
|---------|---------|
| User delete session | Owner can remove a session and related artifacts |
| Retention | Scheduled cleanup of old inactive sessions unless marked exempt |
| Admin | Privileged roles can run bulk reset or memory invalidation in the app deployment |

---

## Routing examples

| User message | Path | Why |
|--------------|------|-----|
| `Hi` | Chitchat | Social |
| `What can I ask about campaigns?` | Discovery | Catalog intent |
| `Show revenue by month` | Analytics | Data / chart intent |
| `Why?` (after a chart) | Analytics | Session follow-up |
| `Why?` (no prior data turn) | Analytics (default) | Not treated as pure chitchat |
| `Hi` (after a discovery answer) | Chitchat | Social wins; discovery does not block chitchat |

---

## Filtered cohort report (non-stream path)

Analysts can open a **structured cohort form** from the chat composer (separate from typing a natural-language question). This path **does not** use the chat stream API or LangGraph; it uses the **cohort API** through the BFF. When a session id is supplied, the backend still persists a normal **chat** interaction so the thread and audit UI stay consistent.

```mermaid
sequenceDiagram
  participant U as User
  participant FE as Next.js UI
  participant PX as BFF proxy
  participant CO as Cohort API
  participant DB as PostgreSQL

  U->>FE: Open cohort form
  FE->>FE: Review filters and confirm
  FE->>PX: POST cohort request + session id
  PX->>CO: Authenticated cohort run
  CO->>CO: SQL over lake + matrix transform
  CO->>DB: Save chat interaction
  CO-->>FE: Matrix / LTV payload + processing steps
  FE->>FE: Append user + agent messages
  FE-->>U: Matrix chart + optional LTV panel
```

| Aspect | NL chat (stream) | Filtered cohort tool |
|--------|------------------|----------------------|
| Entry | Typed question | Composer form + confirm step |
| API | Chat stream (SSE) | Cohort API (single response) |
| Agent | LangGraph + tools | Dedicated cohort pipeline |
| Typical output | Chart from agent tools | Retention matrix (+ optional LTV projection) |
| Streaming | SSE phases | No SSE; `processing_steps` on POST for audit |
| Routing metadata | `analytics`, etc. | `cohort_report` / `filtered_cohort` |

**Deliverables (conceptual):** User selects matrix, LTV projection, or both; optional expert-analysis prose per deliverable. Form options (date bounds, plan filters, marketing dimensions) come from cohort form-options APIs.

**Contrast:** Natural-language cohort questions (e.g. heatmaps by month) still use the **analytics** path and warehouse tools. The tool path uses the **retention matrix** cell model and shared admin-style cohort filtering—not the same shape as ad-hoc NL cohort charts.

**Drill-down:** Matrix cells can open a drawer with per-span revenue and optional projected metrics; separate from the LTV projection slider curve.

---

## Where to read more

| Topic | Location |
|-------|----------|
| System topology | [[2026-Reporting-AI-Agent-Architecture]] |
| Backend role & config | [[2026-Reporting-AI-Agent-Backend]] |
| Frontend / BFF | [[2026-Reporting-AI-Agent-Frontend]] |
| Full routing rules, code, tests, admin APIs | Private **application monorepo** |
