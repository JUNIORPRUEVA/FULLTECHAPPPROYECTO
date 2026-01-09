import 'dotenv/config';

import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

/**
 * Script to verify and fix user login issues
 * 
 * Usage:
 *   npm run verify-user -- user@email.com
 *   npm run verify-user -- user@email.com NewPassword123
 * 
 * This will:
 * 1. Check if user exists
 * 2. Check if user estado is 'activo' (and fix it if not)
 * 3. Optionally reset password if provided
 * 4. Output user details and credentials
 */
async function main() {
  const email = process.argv[2];
  const newPassword = process.argv[3];

  if (!email) {
    console.error('Usage: npm run verify-user -- <email> [newPassword]');
    console.error('Example: npm run verify-user -- admin@fulltech.com');
    console.error('Example: npm run verify-user -- admin@fulltech.com NewPass123');
    process.exit(1);
  }

  const prisma = new PrismaClient();
  try {
    const user = await prisma.usuario.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        nombre_completo: true,
        rol: true,
        empresa_id: true,
        estado: true,
        token_version: true,
      },
    });

    if (!user) {
      console.error(`❌ User not found for email: ${email}`);
      console.error(`\nTo create admin user, run: npm run bootstrap-admin`);
      process.exit(2);
    }

    console.log('\n=== USER FOUND ===');
    console.log(`Email: ${user.email}`);
    console.log(`Name: ${user.nombre_completo}`);
    console.log(`Role: ${user.rol}`);
    console.log(`Estado: ${user.estado}`);
    console.log(`Token Version: ${user.token_version}`);

    let needsUpdate = false;
    const updateData: any = {};

    // Check if user is not active
    if (user.estado !== 'activo') {
      console.log(`\n⚠️  WARNING: User estado is '${user.estado}' (should be 'activo')`);
      console.log('✅ Fixing: Setting estado to "activo"...');
      updateData.estado = 'activo';
      needsUpdate = true;
    } else {
      console.log('\n✅ User estado is "activo" - OK');
    }

    // Reset password if provided
    if (newPassword) {
      console.log('\n🔑 Resetting password...');
      const salt = await bcrypt.genSalt(10);
      const password_hash = await bcrypt.hash(newPassword, salt);
      updateData.password_hash = password_hash;
      // Invalidate existing sessions
      updateData.token_version = { increment: 1 };
      needsUpdate = true;
    }

    // Apply updates if needed
    if (needsUpdate) {
      await prisma.usuario.update({
        where: { email },
        data: updateData,
      });
      console.log('✅ User updated successfully!');
    }

    // Output final credentials
    console.log('\n=== LOGIN CREDENTIALS ===');
    console.log(`Email: ${email}`);
    if (newPassword) {
      console.log(`Password: ${newPassword}`);
    } else {
      console.log(`Password: (unchanged)`);
    }
    console.log('\n=== TEST LOGIN ===');
    console.log('You can test login with:');
    console.log(`curl -X POST http://localhost:3000/api/auth/login \\`);
    console.log(`  -H "Content-Type: application/json" \\`);
    console.log(`  -d '{"email":"${email}","password":"YOUR_PASSWORD"}'`);
    console.log('');

    process.exit(0);
  } catch (error) {
    console.error('❌ ERROR:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
