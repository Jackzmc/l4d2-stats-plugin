# L4D2 Stats Plugin

> [!NOTE]
> This is more of a custom personal project that I decided to have open sourced - limited support and some features will not work as they rely on my custom systems (such as "Play Style" and "Rating" in user overview)

A sourcemod plugin for l4d2 that records statistics for all players on the server and a server that shows the statistics. This was designed for co-op, and so versus and other gamemodes may not track statistics correctly.

This is a multi-part project:

* Web server (Astro) serving HTTP templates
* Sourcemod Plugin

Requires a MySQL/MariaDB server, see `stats_database.sql` for the tables.

Demo: https://stats.jackz.me

## Deploying

### Plugin

The plugin can be downloaded from [plugins/l4d2_stats_recorder.smx](./plugins/l4d2_stats_recorder.smx)

### Env Variables

Env variables can be set with a local `.env.local` file, default values can be seen in the `.env` file provided

```env
# Required

DATABASE_URL=mysql://stats@localhost/left4dead2

## URL used for some links
PUBLIC_SITE_URL=https://stats.example.com
## Name of site to use in navbar, <title>
PUBLIC_SITE_NAME=L4D2 Stats
## Description used on home page and any page without it's own description
PUBLIC_SITE_DESC=View all in-game statistics for Left 4 Dead 2, with a leaderboard, game overviews and user statistics

# Optional
## Comma separated list of domains to whitelist for /api routes, or use '*' for any site
API_ALLOWED_ORIGINS=myotherservice.example.com
## Host
HOST=0.0.0.0
## Port for server to listen to
PORT=4321
```

### Docker

Due the nature of Astro, the site URL is baked into the files on build time. No pre-built docker image is available, but you could build your own easily with the provided Dockerfile.

Pulls env variables from [.env files (Vite's docs)](https://vite.dev/guide/env-and-mode.html#env-files). ALL .env files are copied, so overwrite settings with .env.production if needed

```bash
docker build -t l4d2-stats-website .
```

### Manual

Requires [pnpm](https://pnpm.io/)

Pulls env variables from [.env files (Vite's docs)](https://vite.dev/guide/env-and-mode.html#env-files)

```bash
# install dependencies
pnpm install --production

# build site for production, produces files in dist/
pnpm build
```

### External Nginx

The docker server has express.js serve the UI's static files, but it may be better to use an external reverse proxy

This serves static files in `/var/www/stats.jackz.me` through nginx, and all `/api/*` requests to the API server.

The demo server does not use docker but has UI built and deployed to /var/www/stats.jackz.me and the *.js copied to server folder and uses the same config below.

```nginx
server {
    listen 80;

    server_name stats.jackz.me;
    
    location /api/ {
        proxy_pass http://localhost:8989;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $http_host;
    }
}
```

## Development

```bash
# install all dependencies
pnpm i

# serve dev server on localhost:4321
pnpm dev
```
