# DZ Smart Seller — integration milestone

This branch combines the deployment of the two existing projects without changing either project's source files:

- **Postmill** (this repository): publishing calendar, multi-channel management, campaigns, analytics, cross-channel engagement, AI design tools.
- **OpenPost** (the `Facebook-2` repository): content workflows, media library, image/video editors, publishing and analytics.

## Important status

This is a **side-by-side deployment milestone with a shared launch portal**, not yet a single unified application frontend. The two applications keep separate databases, accounts, configuration and social connections. A shared login, shared campaign model, cross-app navigation and a common marketing-memory service require a later application-level integration.

## Local requirements

- Docker Engine and Docker Compose plugin.
- A machine with enough memory and disk for both applications and PostgreSQL/Redis. A computer with 4 GB RAM may struggle to run both locally; use one service at a time for development or a remote host if needed.
- OpenSSL, to generate random secrets.

## Configure

From the repository root:

```sh
cp .env.dz-smart-seller.example .env.dz-smart-seller
```

Replace every `REPLACE_WITH_RANDOM_HEX_SECRET` value with a unique secret generated using:

```sh
openssl rand -hex 32
```

Do not reuse the same secret across variables. Keep `.env.dz-smart-seller` private and never commit it.

For local testing, keep the default URLs:
- DZ Smart Seller portal: http://localhost:3000
- Postmill: http://localhost:4007
- OpenPost: http://localhost:8080

For public deployment, do not use the local defaults. Configure real HTTPS URLs, a reverse proxy, secure signup settings, backups, and provider callback URLs before connecting social accounts.

The portal at port 3000 provides one Arabic starting page with links to both services. It does not embed their screens or merge authentication/data yet.

## Validate before starting

```sh
docker compose --env-file .env.dz-smart-seller \
  -f docker-compose.yaml \
  -f docker-compose.dz-smart-seller.yml config
```

Fix any missing environment variable or Compose validation error before starting services.

## Start

```sh
docker compose --env-file .env.dz-smart-seller \
  -f docker-compose.yaml \
  -f docker-compose.dz-smart-seller.yml up -d
```

Inspect logs:

```sh
docker compose --env-file .env.dz-smart-seller \
  -f docker-compose.yaml \
  -f docker-compose.dz-smart-seller.yml ps

docker compose --env-file .env.dz-smart-seller \
  -f docker-compose.yaml \
  -f docker-compose.dz-smart-seller.yml logs --tail=100
```

## Acceptance checks

1. Compose configuration validates with no unresolved required variables.
2. Postmill PostgreSQL reports healthy and Postmill can load at port 4007.
3. Redis health check passes and Postmill starts without Redis connection errors.
4. OpenPost reports ready at `http://localhost:8080/api/v1/ready` and its health check passes.
5. Create separate test accounts in both apps; do not use production tokens during smoke tests.
6. In each app, verify media upload, save a draft, and test scheduling with a non-sensitive test account.
7. Verify that secrets do not appear in Git, browser bundles, logs, or screenshots.
8. Confirm backups and restore procedures before using real customer data.

## Current limitations

- This overlay has not been run in this environment because a local Docker runtime and network access to pull the images are not available here. Treat it as a proposed integration branch until the validation and smoke checks above pass.
- AI generation and some stock-media integrations need configured API keys and may incur provider costs. OpenPost AI workflows are disabled by default in this combined template to avoid unexpected usage.
- Social posting requires valid provider configuration, permissions, and often review by the relevant platform. Marketplace and group automation is not implied.
- The two apps do not share authentication, database tables, media libraries, campaign state or analytics yet.
- The upstream projects are licensed under AGPL-3.0. Preserve their license and notices, and review source-distribution obligations before offering a modified network service.

## Next engineering phase

1. Add a small DZ Smart Seller portal that links to both applications and shows their health status.
2. Define a versioned internal integration API for products, campaigns, content assets and publication status.
3. Add an adapter layer rather than directly sharing database tables across applications.
4. Add shared authentication only after choosing and testing a supported SSO/OIDC design.
5. Add cross-app workflow orchestration and marketing memory after the adapter contract is stable.
6. Run the full CI suites for both upstream projects and an end-to-end test against a staging deployment.
