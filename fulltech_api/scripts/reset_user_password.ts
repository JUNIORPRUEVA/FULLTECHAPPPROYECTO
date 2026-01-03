import 'dotenv/config';

import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

async function main() {
  const email = process.argv[2];
  const newPassword = process.argv[3];

  if (!email || !newPassword) {
    // Intentionally concise; avoid printing secrets.
    // Usage: npm run reset-password -- user@email.com NewPass123
    console.error('Usage: npm run reset-password -- <email> <newPassword>');
    process.exit(1);
  }

  const prisma = new PrismaClient();
  try {
    const user = await prisma.usuario.findUnique({
      where: { email },
      select: { id: true, email: true, empresa_id: true, estado: true },
    });

    if (!user) {
      console.error(`User not found for email: ${email}`);
      process.exit(2);
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(newPassword, salt);

    await prisma.usuario.update({
      where: { email },
      data: {
        password_hash,
        // Invalidate existing sessions
        token_version: { increment: 1 },
      },
    });

    console.log(
      JSON.stringify(
        {
          ok: true,
          user: {
            id: user.id,
            email: user.email,
            empresa_id: user.empresa_id,
            estado: user.estado,
          },
        },
        null,
        2,
      ),
    );
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((e) => {
  console.error('ERR', e?.message ?? String(e));
  process.exit(1);
});
