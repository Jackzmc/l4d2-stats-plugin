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

## Plugin

The plugin can be downloaded from [plugins/l4d2_stats_recorder.smx](./plugins/l4d2_stats_recorder.smx)

## Env Variables

```env
# Defaults

MYSQL_HOST=localhost
MYSQL_DB=left4dead2
MYSQL_USER=left4dead2
MYSQL_PASSWORD=left4dead2

# Optional
## Comma separated list of domains to whitelist
CORS_WHITELIST=stats.example.com 
## Port for server to listen to
WEB_PORT=8080
```

## Docker

A docker image is available at [https://hub.docker.com/jackzmc/l4d2-stats-server](https://hub.docker.com/repository/docker/jackzmc/l4d2-stats-server)

An addition a [docker-compose.yml](./docker-compose.yml) file is included. It does not include a database, as you should use the same database sourcemod is using.

`docker run jackzmc/l4d2-stats-server:latest`

## Manual

```bash
# build ui
cd website-ui; yarn && yarn build; cp dist/ /var/www/l4d2-stats

# run server
cd website-api; yarn && node index.js
```

## External Nginx

The docker server has express.js serve the UI's static files, but it may be better to use an external reverse proxy

This serves static files in `/var/www/stats.jackz.me` through nginx, and all `/api/*` requests to the API server.

The demo server does not use docker but has UI built and deployed to /var/www/stats.jackz.me and the *.js copied to server folder and uses the same config below.

```nginx
server {
    listen 80;

    server_name stats.jackz.me;
    root /var/www/stats.jackz.me;
    
    location / {
        try_files $uri/ $uri /index.html;
    }
    
    location /api/ {
        proxy_pass http://localhost:8989;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $http_host;
    }
}
```

## Building

You can build the sourcemod plugin from the scripting/ folder.

The webserver is built using VueJS and you can just cd to the folder and run `<yarn/npm> install && <yarn/npm run> build`

The api server, just install npm packages with yarn or npm, and run index.js. You do need to set the following environment variables to hook to mysql:

```env
MYSQL_HOST=
MYSQL_USER=l4d2
MYSQL_DB=l4d2
MYSQL_PASSWORD=
# optional
WEB_PORT=8080 #default
```
