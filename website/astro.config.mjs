// @ts-check
import { defineConfig } from 'astro/config';
import { loadEnv } from "vite";

import node from "@astrojs/node";


const env = loadEnv(process.env.NODE_ENV ?? "production", process.cwd(), "");

// https://astro.build/config
export default defineConfig({
  output: "server",

  adapter: node({
    mode: "standalone"
  }),

  site: env.PUBLIC_SITE_URL ?? "https://stats.jackz.me",

  security: {
    checkOrigin: false
  }
});