import type { FastifyInstance, FastifyPluginOptions } from 'fastify';
export default async function ( fastify: FastifyInstance, opts: FastifyPluginOptions ) {
  fastify.get('/', async function (request, reply) {
    return { root: true }
  })
}
