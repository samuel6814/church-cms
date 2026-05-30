# Walkthrough: Connect Neon, Render (Docker), and Vercel

Step-by-step guide for [church-cms](https://github.com/samuel6814/church-cms).  
**Order matters:** Neon → Render (API) → Vercel (UI) → update Render CORS.

Estimated time: **45–60 minutes** (first time).

| Step | Service | You get |
|------|---------|---------|
| 1 | Neon | `DB_URL` |
| 2 | Render (Docker) | `https://church-cms-api.onrender.com` |
| 3 | Vercel | `https://your-app.vercel.app` |
| 4 | Render (env update) | CORS allows Vercel |
| 5 | Smoke tests | Working login |

Reference: [DEPLOYMENT.md](./DEPLOYMENT.md) (architecture + troubleshooting).

---

## Before you start

- [ ] GitHub account with access to `samuel6814/church-cms` (or your fork).
- [ ] Accounts: [neon.tech](https://neon.tech), [render.com](https://render.com), [vercel.com](https://vercel.com).
- [ ] Repo cloned locally (optional, for generating `APP_KEY`):

```bash
git clone https://github.com/samuel6814/church-cms.git
cd church-cms
composer install
php artisan key:generate --show
```

Copy the `base64:…` key — you will paste it into Render.

---

## Part 1 — Neon (PostgreSQL)

### 1.1 Create a project

1. Log in to [Neon Console](https://console.neon.tech).
2. Click **New Project**.
3. Name it e.g. `church-cms`.
4. Region: pick one close to your Render region (e.g. **US East** if Render is Oregon/US).
5. Click **Create**.

### 1.2 Get the connection string

1. Open the project → **Dashboard**.
2. Under **Connection details**, choose **Connection string**.
3. Select **Direct connection** (host like `ep-xxxxx.us-east-2.aws.neon.tech` — **no** `-pooler` in the hostname).
4. Copy the URL. It looks like:

```text
postgresql://neondb_owner:xxxxxxxx@ep-cool-name-12345678.us-east-2.aws.neon.tech/neondb?sslmode=require
```

5. Save this as **`DB_URL`** (you will paste it into Render only — never commit it).

### 1.3 (Optional) Create a dedicated database name

Default database is often `neondb`. You can rename or create `church_cms` in the **SQL Editor**:

```sql
CREATE DATABASE church_cms;
```

Then update the path in `DB_URL` to `/church_cms` if you use that name.

**Checkpoint:** You have a **direct** Postgres URL with `?sslmode=require`.

---

## Part 2 — Render (Laravel API, Docker)

### 2.1 Create the web service

1. Log in to [Render Dashboard](https://dashboard.render.com).
2. Click **New +** → **Web Service**.
3. Connect **GitHub** if not already connected; authorize Render.
4. Find and select repository **`samuel6814/church-cms`** (or your fork).

### 2.2 Critical settings (Docker, not PHP)

On the create-service form, set:

| Field | Value |
|-------|--------|
| **Name** | `church-cms-api` (or any name; URL will reflect this) |
| **Region** | Same region as Neon if possible |
| **Branch** | `main` |
| **Root Directory** | *(leave blank)* |
| **Environment** | **Docker** ← do **not** choose PHP |
| **Dockerfile Path** | `./Dockerfile` |
| **Instance type** | Free (or paid if you need always-on) |

Render should detect `Dockerfile` at the repo root. If you see “PHP” or “Native”, switch to **Docker**.

### 2.3 Alternative: Blueprint from `render.yaml`

1. **New +** → **Blueprint**.
2. Connect the repo; Render reads [`render.yaml`](../render.yaml).
3. Review service `church-cms-api` (`runtime: docker`).
4. Apply the blueprint, then add secret env vars in the next section.

### 2.4 Environment variables

Open the service → **Environment** → add:

| Key | Value | Notes |
|-----|--------|--------|
| `APP_KEY` | `base64:…` from `php artisan key:generate --show` | Required |
| `APP_URL` | `https://church-cms-api.onrender.com` | Use your actual Render URL after first deploy |
| `DB_URL` | Paste Neon **direct** URL | Secret |
| `FRONTEND_URL` | `https://placeholder.vercel.app` | Temporary; update after Part 3 |

Variables already in `render.yaml` (you can confirm they exist):

- `APP_ENV=production`
- `APP_DEBUG=false`
- `AUTORUN_LARAVEL_MIGRATION=true`
- `DB_CONNECTION=pgsql`
- `LOG_CHANNEL=stderr`

Click **Save Changes**.

### 2.5 Deploy

1. Click **Manual Deploy** → **Deploy latest commit** (or wait for auto-deploy on push to `main`).
2. Open **Logs** and watch the Docker build:
   - `composer install`
   - Image start
   - `php artisan migrate --force` (from `AUTORUN_LARAVEL_MIGRATION`)
3. Wait until status is **Live**.

### 2.6 Note your API URL

Render shows something like:

```text
https://church-cms-api.onrender.com
```

**Health check:**

```bash
curl https://church-cms-api.onrender.com/up
```

Expect HTTP **200**.

### 2.7 Seed the database (first time only)

Free tier: use **Render Shell** (if available) or run locally against Neon:

**Option A — Render Shell**

1. Service → **Shell**.
2. Run:

```bash
php artisan db:seed --force
```

**Option B — Local (with Neon `DB_URL` in `.env`)**

```bash
# In .env temporarily:
# DB_CONNECTION=pgsql
# DB_URL=<your neon direct url>

php artisan migrate --force --seed
```

Default admin after seed:

- Email: `admin@wis-cms.local`
- Password: `Admin@12345`

**Option C — API test without seed**

Login will fail until seed runs; `/up` should still return 200.

**Checkpoint:** API URL works; `/up` returns 200.

---

## Part 3 — Vercel (React frontend)

### 3.1 Import the project

1. Log in to [Vercel Dashboard](https://vercel.com/dashboard).
2. Click **Add New…** → **Project**.
3. Import **GitHub** → select **`samuel6814/church-cms`**.
4. **Framework Preset:** Vercel should detect **Vite** (from [`vercel.json`](../vercel.json)).

### 3.2 Build settings (verify)

| Setting | Expected value |
|---------|----------------|
| **Root Directory** | `./` |
| **Build Command** | `npm run build:spa` |
| **Output Directory** | `dist` |
| **Install Command** | `npm ci` |

These come from `vercel.json`; only override if the UI differs.

### 3.3 Environment variables

Before deploying, open **Environment Variables**:

| Name | Value | Environments |
|------|--------|--------------|
| `VITE_API_URL` | `https://church-cms-api.onrender.com/api` | Production, Preview, Development |
| `VITE_APP_NAME` | `WIS-CMS` | Production, Preview |

Replace the host with **your** Render URL. The value **must end with `/api`**.

See [`.env.vercel.example`](../.env.vercel.example).

### 3.4 Deploy

1. Click **Deploy**.
2. Wait for build log: `vite build --config vite.config.spa.js` → `dist/`.
3. When finished, copy the production URL, e.g.:

```text
https://church-cms.vercel.app
```

### 3.5 Preview deployments

Each PR gets a preview URL. Add preview URLs to Render `FRONTEND_URL` as comma-separated values if you need to test previews:

```text
https://church-cms.vercel.app,https://church-cms-git-feat-xxx.vercel.app
```

**Checkpoint:** Vercel URL loads the login page (styles may load; login may fail until Part 4).

---

## Part 4 — Connect Vercel ↔ Render (CORS)

The browser blocks API calls if Render does not allow your Vercel origin.

1. Render → **church-cms-api** → **Environment**.
2. Set **`FRONTEND_URL`** to your Vercel production URL **only** (no trailing slash):

```text
https://church-cms.vercel.app
```

3. Confirm **`APP_URL`** is your Render URL with `https://`.
4. **Save** → Render will redeploy (or trigger **Manual Deploy**).

CORS is configured in [`config/cors.php`](../config/cors.php) using `FRONTEND_URL`.

---

## Part 5 — End-to-end verification

### 5.1 Browser

1. Open your Vercel URL.
2. Open DevTools → **Network**.
3. Log in with `admin@wis-cms.local` / `Admin@12345`.
4. Confirm:
   - Request goes to `https://….onrender.com/api/auth/login` (not Vercel).
   - Status **200**; no CORS errors in **Console**.

### 5.2 Command line

```bash
# API health
curl -s -o /dev/null -w "%{http_code}\n" https://church-cms-api.onrender.com/up

# Login (after seed)
curl -s -X POST https://church-cms-api.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"email\":\"admin@wis-cms.local\",\"password\":\"Admin@12345\"}"
```

Expect JSON with `"token"` and `"user"`.

### 5.3 Checklist

- [ ] Neon: direct `DB_URL` on Render
- [ ] Render: **Docker** environment, not PHP
- [ ] Render: `APP_KEY`, `APP_URL`, `DB_URL`, `FRONTEND_URL` set
- [ ] Render: `/up` → 200
- [ ] Database migrated (and seeded for login)
- [ ] Vercel: `VITE_API_URL` ends with `/api`
- [ ] Vercel: app loads, login works, no CORS errors
- [ ] Change default admin password before public demo

---

## Part 6 — Ongoing workflow (hackathon)

1. Branch from `develop`: `git checkout -b feat/my-ui-change`.
2. Edit only `resources/js/**`, `resources/css/**` (see [HACKATHON.md](./HACKATHON.md)).
3. Push → open PR to `develop`.
4. Vercel creates a **Preview** deployment automatically.
5. Merge to `main` when ready → Vercel **Production** and Render **auto-deploy** (if enabled).

You do **not** need to redeploy Neon for UI-only changes.

---

## Troubleshooting

| Problem | What to do |
|---------|------------|
| Render offers PHP only | Delete service; recreate with **Environment: Docker** |
| Build fails on `composer install` | Check Render logs; ensure `composer.lock` is in repo |
| `/up` 502 / deploy failed | Check logs for OOM; free tier may need cold start retry |
| CORS error | `FRONTEND_URL` must match Vercel URL exactly (`https`, no trailing `/`) |
| Login 401 | Run `php artisan db:seed --force` on Neon DB |
| API calls hit Vercel domain | Fix `VITE_API_URL` on Vercel; redeploy |
| Migration error on Neon | Use **direct** connection string, not pooler |
| Blank page on Vercel refresh | `vercel.json` rewrites should send `/*` → `/index.html` |

More detail: [DEPLOYMENT.md § Troubleshooting](./DEPLOYMENT.md#7-troubleshooting).

---

## Quick reference (copy-paste)

**Render (Docker API)**

```text
APP_URL=https://<your-service>.onrender.com
DB_URL=<neon-direct-url>
FRONTEND_URL=https://<your-app>.vercel.app
APP_KEY=base64:...
```

**Vercel (React)**

```text
VITE_API_URL=https://<your-service>.onrender.com/api
VITE_APP_NAME=WIS-CMS
```

---

## Related docs

- [DEPLOYMENT.md](./DEPLOYMENT.md) — architecture and env templates
- [HACKATHON.md](./HACKATHON.md) — UI-only scope
- [`prod_assist/`](../prod_assist/) — production playbooks
