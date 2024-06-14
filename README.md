# L4D2 Stats Plugin

NOTE: This is more of a custom personal project that I decided to have open sourced - limited support and some features will not work as they rely on my custom systems (such as "Play Style" and "Rating" in user overview)

A plugin for l4d2 that records statistics for all players on the server and shows it publicly on a website. This is a 3-part project.
* Frontend UI
* Backend API
* Sourcemod Plugin

Requires a MySQL server for statistic storage.

Demo: https://stats.jackz.me

### Building
You can build the sourcemod plugin from the scripting/ folder.

The webserver is built using VueJS and you can just cd to the folder and run `<yarn/npm run> build`

The api server, just install npm packages with yarn or npm, and run index.js. You do need to set the following environment variables to hook to mysql:
`MYSQL_USER, MYSQL_DB, MYSQL_PASSWORD, MYSQL_HOST`
Set the port (default 8080) with `WEB_PORT`

The demo server is setup as followed:
1. The UI is served from static files (/var/www/stats.l4d2.jackz.me)
2. /api/ route is proxied to the api server running locally

Example nginx configuration: (implies nodejs server is running on same server on port 8989, set WEB_PORT env for that)
```
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
