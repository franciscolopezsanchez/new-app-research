import type { FastifyInstance } from 'fastify'
import { syncUser, getMe } from './auth.service.js'

export async function authRoutes(app: FastifyInstance) {
  // Called by mobile after first Supabase login — upserts the user row
  app.post('/sync-user', {
    onRequest: [app.authenticate],
    handler: async (request, reply) => {
      const payload = request.user as { sub: string; email: string }
      const user = await syncUser({ authId: payload.sub, email: payload.email })
      return reply.code(201).send(user)
    },
  })

  // Returns current user + their school memberships
  app.get('/me', {
    onRequest: [app.authenticate],
    handler: async (request, reply) => {
      const payload = request.user as { sub: string }
      const user = await getMe(payload.sub)
      if (!user) return reply.code(404).send({ message: 'User not found' })
      return reply.send(user)
    },
  })
}
