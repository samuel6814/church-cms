# Hackathon — Church CMS (UI only)

## Scope (strict)

**In scope**

- `resources/js/**` — React pages, components, routing, API client usage
- `resources/css/**` — Tailwind / global styles
- `resources/views/**` — Blade shell only if needed for layout/meta

**Out of scope — do not change**

- `app/**` — controllers, models, policies, services
- `database/**` — migrations, seeders, factories
- `routes/api.php`, `routes/console.php`
- `config/**` (unless a maintainer explicitly approves an infra hotfix)

Production: **Neon (Postgres)** backs the API on **Render (Docker)**; the React app is on **Vercel**. Local Herd + SQLite is fine for UI-only work.

## Git workflow

Follow [`prod_assist/git-workflow.md`](../prod_assist/git-workflow.md):

| Branch | Use |
|--------|-----|
| `develop` | Default — open PRs here |
| `feat/<slug>` | One hackathon feature or screen refresh |
| `main` | Production / demo deploy |

```bash
git fetch origin --prune
git checkout develop
git pull origin develop
git checkout -b feat/your-feature
# … UI commits …
git push -u origin feat/your-feature
```

Open a PR: **base `develop`** ← compare `feat/your-feature`.

## Local UI dev (Herd)

```bash
composer install
npm install
cp .env.example .env   # if needed
php artisan key:generate
# SQLite: touch database/database.sqlite && php artisan migrate --seed
npm run dev              # Vite HMR — keep Herd serving http://church_cms.test
```

Login after seed: `admin@wis-cms.local` / `Admin@12345`

## Production deploy

See **[DEPLOYMENT.md](./DEPLOYMENT.md)** — Vercel (frontend) + Render Docker (API) + Neon (database).

Reference playbooks (do not duplicate blindly; verify versions in repo):

- [`prod_assist/production-laravel.md`](../prod_assist/production-laravel.md)
- [`prod_assist/vercel-laravel.md`](../prod_assist/vercel-laravel.md)
- [`prod_assist/render-external-cron-pattern.md`](../prod_assist/render-external-cron-pattern.md)
- [`prod_assist/ENV_WORKFLOW.md`](../prod_assist/ENV_WORKFLOW.md)

## API from the frontend (split deploy)

Production uses **two hosts**:

- **Vercel** — React (`npm run build:spa`)
- **Render** — Laravel API

Set `VITE_API_URL` on Vercel (e.g. `https://church-cms-api.onrender.com/api`).  
Locally on Herd, leave it unset — `resources/js/api/axios.js` defaults to `/api`.

```bash
# Optional: UI-only dev against production/staging API
cp .env.vercel.example .env.local
npm run dev:spa
```
