import Fastify from 'fastify'
import cors from '@fastify/cors'
import helmet from '@fastify/helmet'
import jwt from '@fastify/jwt'
import { authRoutes } from './modules/auth/auth.routes.js'

const app = Fastify({ logger: true })

// Plugins
await app.register(helmet)
await app.register(cors, { origin: true })
await app.register(jwt, {
  secret: process.env.SUPABASE_JWT_SECRET!,
})

// Decorate request with authenticate helper
app.decorate('authenticate', async function (request: any, reply: any) {
  try {
    await request.jwtVerify()
  } catch (err) {
    reply.send(err)
  }
})

// Routes
await app.register(authRoutes, { prefix: '/auth' })

app.get('/health', async () => ({ status: 'ok' }))

const port = Number(process.env.PORT) || 3000
await app.listen({ port, host: '0.0.0.0' })
