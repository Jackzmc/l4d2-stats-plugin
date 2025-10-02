import path from 'node:path'
import AutoLoad from '@fastify/autoload'
import Sensible from '@fastify/sensible'
import Cache from '@fastify/caching'
import Env from '@fastify/env'
import MySQL from '@fastify/mysql'
import helmet from '@fastify/helmet'

import Fastify from 'fastify'

const app = Fastify( {
  trustProxy: process.env.NODE_ENV === "production",
  logger: true
} )

/** Define custom decorators */
declare module 'fastify' {
  export interface FastifyInstance {
    // db: Pool;
  }
  export interface FastifyRequest {
  }
}

app.register( Sensible )

// TODO: move plugins to this folder
app.register(AutoLoad, {
  dir: path.join( import.meta.dirname, 'plugins' ),
  forceESM: true
})

app.register(AutoLoad, {
  dir: path.join( import.meta.dirname, 'routes' ),
  forceESM: true
})

const LISTEN_HOST = process.env.LISTEN_HOST || "0.0.0.0"
const LISTEN_PORT = Number(process.env.LISTEN_PORT) || 8081
app.listen( { host: LISTEN_HOST, port: LISTEN_PORT })