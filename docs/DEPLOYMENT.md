# Deployment — Church CMS (split stack)

| Layer | Host | Technology |
|-------|------|------------|
| **React SPA** | [Vercel](https://vercel.com) | Vite (`npm run build:spa`) |
| **Laravel API** | [Render](https://render.com) | **Docker** (`serversideup/php:8.4-fpm-nginx`) |
| **Database** | [Neon](https://neon.tech) | PostgreSQL |

```
Browser  →  https://your-app.vercel.app          (React + React Router)
                │  axios → VITE_API_URL
                ▼
           https://church-cms-api.onrender.com    (Docker: nginx + PHP-FPM + Laravel)
                │  /api/*
                ▼
           Neon Postgres (DB_URL)
```

**Important:** On Render, use **Environment: Docker** and the root [`Dockerfile`](../Dockerfile). Do **not** select Render’s native PHP environment — PHP runs inside the container image only.

**Step-by-step setup:** [DEPLOY-WALKTHROUGH.md](./DEPLOY-WALKTHROUGH.md) (Neon → Render Docker → Vercel → CORS → smoke tests).

---

## Repository layout (deploy-related)

| Path | Purpose |
|------|---------|
| [`Dockerfile`](../Dockerfile) | API image for Render (no frontend build) |
| [`render.yaml`](../render.yaml) | Render Blueprint (`runtime: docker`) |
| [`vercel.json`](../vercel.json) | Vercel Vite SPA + SPA rewrites |
| [`vite.config.spa.js`](../vite.config.spa.js) | Standalone React build → `dist/` |
| [`index.html`](../index.html) | Vercel SPA entry |
| [`.env.vercel.example`](../.env.vercel.example) | Frontend env template (`VITE_API_URL`) |
| [`.env.production.example`](../.env.production.example) | API env template (Render + Neon) |
| [`config/cors.php`](../config/cors.php) | Allows Vercel origin via `FRONTEND_URL` |

---

## 1. Neon (database)

1. Create a project at [neon.tech](https://neon.tech).
2. Create a database (e.g. `church_cms`).
3. Copy the **direct** connection string (`ep-….neon.tech`, **not** `-pooler`) for migrations on Render.

```env
DB_CONNECTION=pgsql
DB_URL=postgresql://user:pass@ep-xxx.neon.tech/neondb?sslmode=require
```

Migrations on first Render deploy: `AUTORUN_LARAVEL_MIGRATION=true` in [`render.yaml`](../render.yaml), or manually:

```bash
php artisan migrate --force --seed
```

Default login after seed: `admin@wis-cms.local` / `Admin@12345`

---

## 2. Render (API — Docker)

### Render dashboard settings

| Setting | Value |
|---------|--------|
| **Service type** | Web Service |
| **Environment** | **Docker** (not PHP) |
| **Dockerfile path** | `./Dockerfile` |
| **Health check path** | `/up` |
| **Branch** | `main` or `develop` |

### Blueprint (optional)

Dashboard → **Blueprints** → connect repo → apply [`render.yaml`](../render.yaml).  
Service name: `church-cms-api`, `runtime: docker`, `dockerfilePath: ./Dockerfile`.

### Environment variables (Render Dashboard)

| Variable | Required | Example |
|----------|----------|---------|
| `APP_KEY` | Yes | `php artisan key:generate --show` |
| `APP_URL` | Yes | `https://church-cms-api.onrender.com` |
| `DB_URL` | Yes | Neon **direct** URL |
| `FRONTEND_URL` | Yes | `https://your-app.vercel.app` (comma-separated for preview URLs) |
| `CRON_TOKEN` | Optional | For external cron — see [`prod_assist/render-external-cron-pattern.md`](../prod_assist/render-external-cron-pattern.md) |

Other production defaults are in [`render.yaml`](../render.yaml) (`LOG_CHANNEL=stderr`, `QUEUE_CONNECTION=database`, etc.).

### What the Docker image does

- Base: `serversideup/php:8.4-fpm-nginx` (nginx + PHP 8.4 + FPM)
- `composer install --no-dev` at build time
- **No** `npm` / Vite in the image (UI is on Vercel)
- `AUTORUN_LARAVEL_MIGRATION=true` runs migrations on container start
- `trustProxies` in [`bootstrap/app.php`](../bootstrap/app.php) for HTTPS behind Render’s load balancer

### Smoke tests

```bash
curl -s -o /dev/null -w "%{http_code}" https://church-cms-api.onrender.com/up
# expect 200

curl -s -X POST https://church-cms-api.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"email":"admin@wis-cms.local","password":"Admin@12345"}'
```

### Free tier notes

- Do **not** enable `AUTORUN_LARAVEL_SCHEDULER` or `AUTORUN_LARAVEL_WORKER` on 512MB plans.
- See [`prod_assist/render-external-cron-pattern.md`](../prod_assist/render-external-cron-pattern.md) for queues/scheduler.

---

## 3. Vercel (React frontend)

1. Import GitHub repo `samuel6814/church-cms`.
2. **Framework preset:** Vite (uses root [`vercel.json`](../vercel.json)).
3. **Build command:** `npm run build:spa` (set automatically by `vercel.json`).
4. **Output directory:** `dist`

### Environment variables (Vercel Dashboard)

Copy from [`.env.vercel.example`](../.env.vercel.example):

| Variable | Value |
|----------|--------|
| `VITE_API_URL` | `https://church-cms-api.onrender.com/api` (must include `/api`) |
| `VITE_APP_NAME` | `WIS-CMS` |

After deploy, set Render `FRONTEND_URL` to your Vercel URL so CORS allows the browser.

### Local frontend → remote API

```bash
cp .env.vercel.example .env.local
# Set VITE_API_URL to your Render API
npm run dev:spa
```

### Local full stack (Herd)

Leave `VITE_API_URL` unset; [`resources/js/api/axios.js`](../resources/js/api/axios.js) uses `/api` on `http://church_cms.test`.

```bash
npm run dev    # with Herd serving the Laravel app
```

---

## 4. CORS and auth

- API auth uses **Bearer tokens** in `localStorage` (Sanctum).
- [`config/cors.php`](../config/cors.php) allows origins from `FRONTEND_URL`.
- No cookie credentials across origins (`supports_credentials: false`).

---

## 5. Hackathon (UI-only)

See [HACKATHON.md](./HACKATHON.md). Work on `develop` / `feat/*`; change only `resources/js`, `resources/css`, and related env examples.

---

## 6. Git workflow

Maintainer: **jackysmith040** (`jackysmith040@gmail.com`).  
Branches: `develop` (integration), `main` (production deploy).  
Details: [`prod_assist/git-workflow.md`](../prod_assist/git-workflow.md).

---

## 7. Troubleshooting

| Symptom | Fix |
|---------|-----|
| CORS error in browser | Set Render `FRONTEND_URL` to exact Vercel URL (scheme + host) |
| API calls go to Vercel domain | Set Vercel `VITE_API_URL` with `/api` suffix |
| Mixed content / `http://` assets on API | `trustProxies` enabled; set `APP_URL` to `https://…` |
| Render build uses PHP native | Switch service to **Docker**; point to `./Dockerfile` |
| Migrations fail | Use Neon **direct** URL, not pooler, for `DB_URL` on Render |
| 404 on Vercel routes | `vercel.json` rewrites must send `/*` → `/index.html` |

---

## 8. Further reading

- [`prod_assist/production-laravel.md`](../prod_assist/production-laravel.md) — Docker image, Neon, OPCache
- [`prod_assist/ENV_WORKFLOW.md`](../prod_assist/ENV_WORKFLOW.md) — env promotion local → staging → production
- [`prod_assist/vercel-laravel.md`](../prod_assist/vercel-laravel.md) — monolithic PHP on Vercel (**not used** in this project)
