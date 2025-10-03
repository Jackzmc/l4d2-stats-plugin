// @ts-check
import { defineConfig } from 'astro/config';
import { loadEnv } from "vite";

import icon from "astro-icon";
import node from "@astrojs/node";


const env = loadEnv(process.env.NODE_ENV ?? "production", process.cwd(), "");

// https://astro.build/config
export default defineConfig({
  integrations: [icon({
    include: {
      proicons: ["chevron-left", "chevron-right", "search"]
    }
  })],

  output: "server",

  adapter: node({
    mode: "standalone"
  }),

  site: env.PUBLIC_SITE_URL ?? "https://stats.jackz.me",

  security: {
    checkOrigin: false
  },

  server: {
    allowedHosts: true
  },

  redirects: {
    "/leaderboards": {
      status: 302,
      destination: "/leaderboards/1"
    }
  }
});