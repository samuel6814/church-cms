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

Production deploy uses **Neon (Postgres)** on Render or Vercel. Local Herd/SQLite is fine for UI work; production must use Postgres as shipped in the repo.

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

See **[DEPLOYMENT.md](./DEPLOYMENT.md)** — Render + Neon (recommended) and optional Vercel.

Reference playbooks (do not duplicate blindly; verify versions in repo):

- [`prod_assist/production-laravel.md`](../prod_assist/production-laravel.md)
- [`prod_assist/vercel-laravel.md`](../prod_assist/vercel-laravel.md)
- [`prod_assist/render-external-cron-pattern.md`](../prod_assist/render-external-cron-pattern.md)
- [`prod_assist/ENV_WORKFLOW.md`](../prod_assist/ENV_WORKFLOW.md)

## API from the frontend

The SPA uses a **relative** API base (`/api` in `resources/js/api/axios.js`). Same-origin deploy (Render or Vercel) needs no `VITE_API_URL` unless you split frontend and API later.
