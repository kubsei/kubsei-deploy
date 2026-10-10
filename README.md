# kubsei-deploy

How the kubsei backend runs in production: `docker-compose.yml` with Caddy (HTTPS) → kubsei-gateway → kubsei-users / kubsei-editor,
using the images that each service's CI pushes to GHCR. MongoDB is Atlas; the frontend is on Vercel.

| File | What it is |
|---|---|
| `docker-compose.yml` | The stack. Only Caddy publishes ports (80/443). |
| `Caddyfile` | HTTPS for `API_DOMAIN`, proxied to the gateway |
| `.env.example` | Configuration and secrets; copy to `.env` on the server |
| `deploy.sh` | Pins image tags in `.env`, pulls and restarts |
| `.github/workflows/deploy.yml` | Runs `deploy.sh` on the server over SSH (manual) |

## Deploy

From GitHub: **Actions → Deploy → Run workflow**, optionally with a tag per service.

From the server:

```bash
cd /opt/kubsei-deploy
./deploy.sh                       # re-pull the pinned tags (latest = last build of main)
./deploy.sh users=<commit-sha>    # pin / roll back one service
```

Full guide (server setup, secrets, workflow): `docs/` in the workspace — `despliegue.md` and `ci-cd.md`.
