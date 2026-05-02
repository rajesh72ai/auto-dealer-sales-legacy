# AUTOSALES on GCP — Phase A runbook

Lift-and-shift of the AUTOSALES modular monolith to Google Cloud Run + Cloud SQL.
Phase A scope: **app + DB only, no AI**. Phase B re-enables AI via Vertex AI / Gemini.

## Live URLs (deployed 2026-05-02)

| Service | URL |
|---|---|
| Frontend (open this in a browser) | https://autosales-frontend-683448878661.us-central1.run.app |
| Backend  | https://autosales-backend-683448878661.us-central1.run.app |
| Login    | `ADMIN001` / `Admin123` (dealer DLR01) |

The frontend nginx reverse-proxies `/api/*` to the backend, so the browser only
sees one origin — no CORS configuration needed.

## Architecture

```
   Browser
      │
      │ HTTPS
      ▼
  ┌────────────────────┐                      ┌────────────────────┐
  │  Cloud Run         │  /api/* reverse-proxy │  Cloud Run         │
  │  autosales-frontend├──────────────────────▶│  autosales-backend │
  │  nginx + static    │                       │  Spring Boot 3.3   │
  │  Vite build        │                       │  Java 21           │
  └────────────────────┘                       └─────────┬──────────┘
                                                         │
                                              Unix socket │ /cloudsql/...
                                                         ▼
                                                ┌────────────────────┐
                                                │  Cloud SQL         │
                                                │  Postgres 16       │
                                                │  db-f1-micro       │
                                                └────────────────────┘
```

| Layer | GCP service | Tier | Notes |
|---|---|---|---|
| Frontend | Cloud Run | 256 MiB / 1 vCPU | nginx static + `/api` reverse proxy |
| Backend | Cloud Run | 1 GiB / 1 vCPU | Spring Boot, profile `gcp` |
| Database | Cloud SQL Postgres 16 | `db-f1-micro` | 10 GB SSD, no HA, no backup |
| Secrets | Secret Manager | — | DB password + JWT signing key |
| Images | Artifact Registry | — | Docker repo `autosales` |
| Identity | Service Account | — | `autosales-app` with cloudsql.client + secretmanager.secretAccessor |

Both Cloud Run services are configured with `min-instances=0` (scale to zero) and
`max-instances=2` (cost-bounded for the demo).

## Estimated cost

For the trial-credit window, expect roughly:

| Service | Cost |
|---|---|
| Cloud SQL `db-f1-micro` (always-on) | ~$8-10 / month |
| Cloud Run (scale-to-zero, demo traffic) | < $1 / month |
| Artifact Registry (~1 GB) | ~$0.10 / month |
| Cloud Build (~10 builds × 5 min) | < $1 / month |
| Secret Manager (2 secrets) | < $0.10 / month |
| **Total** | **~$10-12 / month** |

The trial $300 credit comfortably covers months of demo usage. Run `teardown.ps1`
between demo windows to drop Cloud SQL ($0 when deleted) if you want to stretch
the credit further.

## Prerequisites

- gcloud CLI authenticated as the project owner: `gcloud auth login`
- Project set: `gcloud config set project auto-sales-ai-enabled`
- Application Default Credentials configured: `gcloud auth application-default login`
- Billing linked to the project

## Deploy from a clean slate

```powershell
cd auto-dealer-sales-modern\gcp

./setup.ps1            # one-time: APIs, Artifact Registry, Cloud SQL, secrets, IAM (~7-10 min)
./deploy-backend.ps1   # build + push + deploy backend; Flyway runs V1-V68 on first boot (~5-7 min)
./deploy-frontend.ps1  # build + push + deploy frontend pointed at backend URL (~3-5 min)
```

On completion, the frontend script prints the public Cloud Run URL. Open it,
login with **`ADMIN001` / `Admin123`** (dealer DLR01).

## Re-deploy after code changes

```powershell
./deploy-backend.ps1   # rebuilds + redeploys backend; Flyway picks up any new migrations
./deploy-frontend.ps1  # rebuilds + redeploys frontend
```

Both scripts are idempotent. Cloud Run does zero-downtime traffic-shifting between revisions.

## Smoke test commands

```powershell
# Backend health
$backend = gcloud run services describe autosales-backend --region=us-central1 --format='value(status.url)'
curl "$backend/actuator/health"

# Login (returns JWT)
$body = '{"userId":"ADMIN001","password":"Admin123"}'
curl -Method POST -Uri "$backend/api/auth/login" -Body $body -ContentType 'application/json'

# Frontend
$frontend = gcloud run services describe autosales-frontend --region=us-central1 --format='value(status.url)'
Start-Process $frontend
```

## Pause / resume Cloud SQL (cost optimization)

Cloud SQL is the only resource that bills 24/7 (~$8-10/mo). Cloud Run scales
to zero when idle and bills nothing. To save money on long pauses without
losing data:

```powershell
./stop-sql.ps1   # ~30s; data preserved; cost drops to ~$1-2/mo (storage only)
./start-sql.ps1  # ~30s; instance becomes RUNNABLE again
```

When SQL is stopped, the backend Cloud Run service can't connect — first request
after restart will reconnect cleanly. Use this for overnight/weekend pauses.

## Tear down (full cleanup)

```powershell
./teardown.ps1                          # drop Cloud Run + Cloud SQL (keep secrets + images)
./teardown.ps1 -AlsoSecrets -AlsoImages # full cleanup
```

## Known issues (clean up before "production")

These don't block the demo but are worth fixing if AUTOSALES on GCP becomes
a real product:

1. **TypeScript errors in registration/warranty pages** — ~30 type errors
   (`label` not in `Column<T>`, missing `totalElements` prop, unused imports).
   Production build skips `tsc` to ship; runtime is fine. Run `npm run typecheck`
   in `frontend/` to surface them. Fix in a dedicated cleanup PR.
2. **Cloud SQL on db-f1-micro** is fine for demo; for production traffic, bump
   to `db-custom-2-7680` and enable HA (`--availability-type=regional`).
3. **No min-instances** — first request after idle has a 1-3s cold start.
   For client-facing demos, set `--min-instances=1` on the backend (~$15/mo).
4. **Cloud SQL no automated backups** — disabled to save cost during demo.
   Re-enable with `gcloud sql instances patch ... --backup-start-time=03:00`.
5. **`--allow-unauthenticated`** on both Cloud Run services — anyone can hit
   the URLs. For internal-only demos, switch to IAP (Identity-Aware Proxy).

## Differences from local Docker Compose stack

| Dimension | Local (master) | GCP (gcp-demo) |
|---|---|---|
| Compose file | `docker-compose.yml` | n/a — Cloud Run |
| Backend image | `Dockerfile` (port 8480) | `Dockerfile.cloudrun` (port `$PORT`) |
| Frontend | `Dockerfile` (Vite dev server) | `Dockerfile.cloudrun` (vite build + nginx) |
| Spring profile | `docker` | `gcp` |
| DB | `postgres:16-alpine` container | Cloud SQL `db-f1-micro` |
| Secrets | `.env` file | Secret Manager |
| AI | OpenClaw + Claude | **disabled in Phase A** (re-enabled Phase B) |

Master is unchanged. The `gcp-demo` branch only adds new files (`Dockerfile.cloudrun`,
`application-gcp.yml`, `nginx.conf`, `gcp/`); nothing existing is modified.

## Phase B preview

Once Phase A is live and demo-ready, Phase B introduces Gemini via Vertex AI:
- New `modules/gemini/` Spring package mirroring `modules/agent/`
- 28-tool catalog mapped to Gemini function declarations
- Phase 3 Safe Action Framework (propose / confirm / undo) reused unchanged
- Native tool-call visibility (closes hardening Gap F)
- Real cost attribution via Cloud Billing → BigQuery export (closes Gap E)
