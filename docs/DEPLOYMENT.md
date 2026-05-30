# Deployment — Church CMS

Stack: **Laravel 13 + React (Vite)** · **Neon Postgres** · **Render** (primary) or **Vercel** (serverless).

## 1. Neon database

1. Create a project at [neon.tech](https://neon.tech).
2. Create a database (e.g. `church_cms`).
3. Copy the **direct** connection string (`ep-….neon.tech`, **not** `-pooler`) for migrations.
4. For Vercel app traffic, you may use the **pooled** endpoint (`-pooler.neon.tech`) per `prod_assist/vercel-laravel.md`.

Set in Render/Vercel:

```env
DB_CONNECTION=pgsql
DB_URL=postgresql://user:pass@ep-xxx.neon.tech/neondb?sslmode=require
```

Run migrations on first deploy (`AUTORUN_LARAVEL_MIGRATION=true` on Render) or manually:

```bash
php artisan migrate --force --seed
```

## 2. Render (recommended)

1. Connect GitHub repo `samuel6814/church-cms`, branch `main` (or `develop` for staging).
2. Use **Blueprint** / `render.yaml` in repo root (Docker, `serversideup/php:8.4-fpm-nginx`).
3. In Render Dashboard → Environment, set secrets:

| Variable | Notes |
|----------|--------|
| `APP_KEY` | `php artisan key:generate --show` |
| `APP_URL` | `https://your-service.onrender.com` |
| `DB_URL` | Neon direct URL |
| `CRON_TOKEN` | Random string if using external cron (see below) |

4. Deploy. Health check: `/up`.
5. **Free tier:** Do **not** enable `AUTORUN_LARAVEL_SCHEDULER` or `AUTORUN_LARAVEL_WORKER`. For queues/scheduler, follow [`prod_assist/render-external-cron-pattern.md`](../prod_assist/render-external-cron-pattern.md) (requires a small `/cron-dispatch` route — infra change, not hackathon UI).

**HTTPS assets:** If CSS/JS load over `http://`, add proxy trust once (infra): `trustProxies(at: '*')` in `bootstrap/app.php` — see `prod_assist/production-laravel.md` §5.

## 3. Vercel (optional)

1. Import repo; framework preset **Other**.
2. Use root `vercel.json` (`vercel-php@0.8.0` = PHP 8.4).
3. Set env vars from `.env.production.example` (Dashboard).
4. `DB_URL` → Neon **pooled** URL recommended.
5. Vercel is read-only except `/tmp` — see `prod_assist/vercel-laravel.md` for `AppServiceProvider` storage path if boot fails.

## 4. Environment templates

| File | Use |
|------|-----|
| `.env.example` | Local / Herd |
| `.env.staging.example` | Staging Render service |
| `.env.production.example` | Production |

Never commit real `.env` files.

## 5. Build assets

Render Dockerfile runs `npm run build` in the image. For Vercel, `buildCommand` in `vercel.json` runs Vite before deploy.

After UI changes:

```bash
npm run build   # optional local check
git push        # CI/host rebuilds
```

## 6. Post-deploy smoke test

- `GET /up` → 200
- Open app URL → login page loads with styles
- `POST /api/auth/login` with seeded admin (if seeded)
- Browse Members / Visitors (read-only smoke)
