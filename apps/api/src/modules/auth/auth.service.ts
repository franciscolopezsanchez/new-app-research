import { prisma } from 'db'

export async function syncUser({ authId, email }: { authId: string; email: string }) {
  return prisma.user.upsert({
    where: { authId },
    update: { email },
    create: { authId, email },
    include: { schoolMemberships: { where: { isActive: true } } },
  })
}

export async function getMe(authId: string) {
  return prisma.user.findUnique({
    where: { authId },
    include: {
      schoolMemberships: {
        where: { isActive: true },
        include: { school: { select: { id: true, name: true } } },
      },
    },
  })
}
