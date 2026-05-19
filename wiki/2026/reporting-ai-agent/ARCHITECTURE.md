# Architecture — Reporting AI Agent (2026)

> Publish to GitHub Wiki as **2026-Reporting-AI-Agent-Architecture** (flat page name).  
> **Public-safe** — topology and patterns only. Security: [README § Security](https://github.com/osuarez1/architectures/blob/main/README.md#security).

Structural view of the reporting agent system: components, data flows, and deployment **patterns**. No runnable code in the architectures repo.

## Keeping this document current

Update when **topology** changes. Use **structural** sibling pages only ([[2026-Reporting-AI-Agent-Chat-Processing]], [[2026-Reporting-AI-Agent-Backend]], [[2026-Reporting-AI-Agent-Frontend]]). Do not add env tables, file paths, or shell commands—those belong in the private application monorepo.

Related: [[Home]] · [Repository README](https://github.com/osuarez1/architectures/blob/main/README.md) · [Publish guide (git)](https://github.com/osuarez1/architectures/blob/main/wiki/README.md)

---

## 1. System context

Logical components of the full stack (implemented in the private application monorepo):

```mermaid
flowchart TB
  subgraph product["Reporting agent product"]
    FE["Next.js frontend"]
    BE["FastAPI backend"]
    ETL["Batch ETL\nRedshift · Glue"]
    DEP["Kubernetes manifests\n(reference)"]
  end
  subgraph docs["Architectures repo"]
    ARCH["ARCHITECTURE.md\nthis page"]
    WIKI["wiki/2026/…"]
  end
  ARCH -.->|describes| product
  WIKI -.->|component detail| product
```

### 1.1 Batch data pipeline (lake source)

ETL maintains warehouse tables and **unloads parquet** to object storage. The API does **not** run Glue; it reads the lake via DuckDB at query time.

```mermaid
flowchart LR
  subgraph etl [Batch ETL]
    SQL["Warehouse SQL"]
    GLUE["Glue jobs"]
  end
  subgraph wh [Warehouse and lake]
    RS[("Warehouse")]
    S3L[("Parquet lake")]
  end
  BE2["FastAPI\nDuckDB over lake"]
  SQL --> RS
  GLUE --> RS
  GLUE --> S3L
  S3L --> BE2
```

**Admin ETL (privileged role):** Admin API can manage schedules/job runs, upload allowlisted SQL/scripts, optional lake sync to local volume, and read-only permission probes. Admin UI uses the frontend BFF proxy.

```mermaid
flowchart LR
  ADM["Admin UI"]
  PX["BFF proxy"]
  BE3["FastAPI\ncloud SDKs"]
  S3SQL["Allowlisted SQL"]
  GL2["Glue"]
  S3L2["Lake parquet"]
  LOC["Local lake path\noptional"]
  ADM --> PX --> BE3
  BE3 --> S3SQL
  BE3 --> GL2
  GL2 --> S3L2
  BE3 --> S3L2
  S3L2 -.->|optional sync| LOC
```

---

## 2. Runtime components (logical)

```mermaid
flowchart LR
  subgraph clients["Clients"]
    BR["Browser"]
  end
  subgraph fe["Frontend"]
    NX["Next.js UI"]
    PX["BFF / proxy routes"]
  end
  subgraph be["Backend"]
    API["FastAPI\nLangGraph / LangChain"]
  end
  subgraph data["Data and external services"]
    PG[("PostgreSQL\nsessions, models, pgvector")]
    DK["DuckDB over parquet\nlocal or remote lake"]
    S3[("Object storage\nartifacts / lake")]
    RD[("Redis\noptional · backend only")]
    LLM["LLM providers"]
  end

  BR --> NX
  NX --> PX
  PX --> API
  API --> PG
  API --> DK
  API --> S3
  API --> RD
  API --> LLM
```

**Rules of thumb**

- Browser uses the **BFF**, not the API origin, for privileged flows.
- **Redis** is backend-only (cache, rate limits, locks).

---

## 3. Local development (logical pattern)

Typical local layout uses containerized frontend/backend and optional Redis; Postgres often runs on the host or a shared dev instance. Parquet may be bind-mounted for offline lake mode.

```mermaid
flowchart TB
  subgraph compose["Local containers (app monorepo)"]
    FES["Frontend"]
    BES["Backend :8000"]
    RED["Redis optional"]
  end
  HOST["Postgres\nhost or managed"]
  LAKE["Local lake volume"]

  FES --> BES
  BES --> HOST
  BES --> LAKE
  BES -.-> RED
```

Compose files and env examples live in the **application monorepo**, not the architectures repo.

---

## 4. Production (logical pattern)

Kubernetes (or similar): frontend and backend deployments, optional Redis, ingress, managed Postgres, volume for local lake copy if used, object storage for lake and artifacts.

```mermaid
flowchart TB
  subgraph cluster["Cluster · app namespace"]
    FP["Frontend"]
    BP["Backend"]
    RS["Redis optional"]
    ING["Ingress"]
  end
  subgraph external["External resources"]
    RDS[("PostgreSQL")]
    VOL["Volume optional"]
    S3P[("Object storage")]
  end

  ING --> FP
  FP --> BP
  BP --> RDS
  BP --> VOL
  BP --> S3P
  BP -.-> RS
```

Deploy scripts and manifests: **application monorepo**.

---

## 5. Chat streaming (sequence)

```mermaid
sequenceDiagram
  participant U as User
  participant N as Next.js UI
  participant P as Proxy route
  participant A as FastAPI
  participant G as Agent graph / tools

  U->>N: Send message
  N->>P: POST stream via proxy
  P->>A: Forward + SSE
  A->>G: Run pipeline
  G-->>A: Tokens / status
  A-->>P: text/event-stream
  P-->>N: SSE
  N-->>U: Render reply
```

---

## 6. Detail index

| Concern | Where to read |
|--------|----------------|
| Repo purpose & security | [Repository README](https://github.com/osuarez1/architectures/blob/main/README.md) |
| Wiki publish workflow | [wiki/README.md (git)](https://github.com/osuarez1/architectures/blob/main/wiki/README.md) |
| Project overview (2026) | [[2026-Reporting-AI-Agent]] |
| Chat question → response | [[2026-Reporting-AI-Agent-Chat-Processing]] |
| Backend / frontend (2026) | [[2026-Reporting-AI-Agent-Backend]], [[2026-Reporting-AI-Agent-Frontend]] |
| Runnable code, Compose, K8s, ETL | Application monorepo (private) |
