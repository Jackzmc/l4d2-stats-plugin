import type { FastifyInstance, FastifyPluginOptions } from 'fastify';
export default async function (fastify: FastifyInstance, opts: FastifyPluginOptions) {
  fastify.get('/', async (req, reply) => {
    return 'this is an example'
  })
}