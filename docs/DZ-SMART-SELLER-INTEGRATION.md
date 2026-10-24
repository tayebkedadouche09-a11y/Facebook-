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

The PowerShell launcher in `integrations/launch-dz-smart-seller.ps1` creates this file and generates a unique random value for each secret on first start. If you create it manually, replace every `REPLACE_WITH_RANDOM_HEX_SECRET` value with a different value generated using:

```sh
openssl rand -hex 32
```

Do not reuse secrets. The generated `.env.dz-smart-seller` file is excluded by `.gitignore`; never commit it or share its contents.

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


## Connect your real Facebook Page (Meta)

**Do not enter your Meta App Secret in the browser, a chat, GitHub, or screenshots.** Configure it only in the private local `.env.dz-smart-seller` file.

1. Create or select an app in [Meta for Developers](https://developers.facebook.com/apps/) and configure Facebook Login.
2. For a public deployment, use a domain with HTTPS first. Set `OPENPOST_URL` / `OPENPOST_APP_URL` to that public origin and set `OPENPOST_MEDIA_URL` to a public HTTPS media origin. A local `localhost` address is not reachable by Meta to fetch image/video files.
3. Add this exact OAuth redirect URI in the Meta app, replacing the example domain with your real OpenPost domain:

   ```text
   https://YOUR-OPENPOST-DOMAIN/api/v1/accounts/facebook/callback
   ```

4. Edit `.env.dz-smart-seller` and replace `OPENPOST_PROVIDER_APPS=[]` with a compact JSON array using your own values:

   ```text
   OPENPOST_PROVIDER_APPS=[{"provider":"facebook","client_id":"YOUR_META_APP_ID","client_secret":"YOUR_META_APP_SECRET","redirect_uri":"https://YOUR-OPENPOST-DOMAIN/api/v1/accounts/facebook/callback"}]
   ```

5. Restart the services with `.\integrations\launch-dz-smart-seller.ps1 start` or the manual Compose command. Open OpenPost, go to **Settings → Workspace → Social accounts**, choose Facebook, sign in, and select the Page you manage.
6. Test a text-only post first. Test image/video separately after public HTTPS media is configured. Verify the post appears on the actual Page and check the app logs if it fails.

OpenPost documents these Page permissions for its Facebook connector: `business_management`, `pages_show_list`, `pages_read_engagement`, `pages_read_user_content`, `pages_manage_engagement`, `pages_manage_metadata`, `pages_manage_posts`, and `pages_messaging`. Request only the access your use case needs; Meta review and business verification may be required before production use. Development-mode testing is limited to app-role users and is not general public approval.

Official reference: https://developers.facebook.com/docs/pages-api/

## Important readiness boundary

This combined stack is **not yet a single shared-data application**. It provides one launch portal and two separate services. They retain separate accounts, settings, data stores, media libraries, and social connections. It is not possible to truthfully certify the whole stack as error-free until the containers start on a real Docker host and a real Meta Page connection and test publication succeed.

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
