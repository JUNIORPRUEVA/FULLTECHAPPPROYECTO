import type { Request, Response } from 'express';
import axios from 'axios';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import {
  crmInstanceCreateSchema,
  crmInstanceUpdateSchema,
  crmInstanceTestConnectionSchema,
  crmChatTransferSchema,
} from './crm_instances.schema';
import { EvolutionClient } from '../../services/evolution/evolution_client';

function actorUserId(req: Request): string {
  const userId = (req as any)?.user?.userId as string | undefined;
  if (!userId) throw new ApiError(401, 'Missing userId');
  return userId;
}

function actorEmpresaId(req: Request): string {
  const empresaId = (req as any)?.user?.empresaId as string | undefined;
  if (!empresaId) throw new ApiError(401, 'Missing empresaId');
  return empresaId;
}

// ======================================
// GET /api/crm/instances - List user instances
// ======================================
export async function listInstances(req: Request, res: Response) {
  const userId = actorUserId(req);
  const empresaId = actorEmpresaId(req);

  const instances = await prisma.$queryRawUnsafe<any[]>(
    `SELECT id, empresa_id, user_id, nombre_instancia, evolution_base_url, is_active, created_at, updated_at
     FROM crm_instancias
     WHERE user_id = $1 AND empresa_id = $2
     ORDER BY is_active DESC, created_at DESC`,
    userId,
    empresaId
  );

  res.json({ items: instances });
}

// ======================================
// GET /api/crm/instances/active - Get active instance
// ======================================
export async function getActiveInstance(req: Request, res: Response) {
  const userId = actorUserId(req);
  const empresaId = actorEmpresaId(req);

  const instances = await prisma.$queryRawUnsafe<any[]>(
    `SELECT id, empresa_id, user_id, nombre_instancia, evolution_base_url, is_active, created_at, updated_at
     FROM crm_instancias
     WHERE user_id = $1 AND empresa_id = $2 AND is_active = TRUE
     LIMIT 1`,
    userId,
    empresaId
  );

  const instance = instances[0] || null;
  res.json({ item: instance });
}

// ======================================
// GET /api/crm/instances/:id - Get instance by ID
// ======================================
export async function getInstance(req: Request, res: Response) {
  const userId = actorUserId(req);
  const empresaId = actorEmpresaId(req);
  const { id } = req.params;

  const instances = await prisma.$queryRawUnsafe<any[]>(
    `SELECT id, empresa_id, user_id, nombre_instancia, evolution_base_url, is_active, created_at, updated_at
     FROM crm_instancias
     WHERE id = $1 AND user_id = $2 AND empresa_id = $3
     LIMIT 1`,
    id,
    userId,
    empresaId
  );

  const instance = instances[0];
  if (!instance) throw new ApiError(404, 'Instance not found');

  res.json({ item: instance });
}

// ======================================
// POST /api/crm/instances - Create new instance
// ======================================
export async function createInstance(req: Request, res: Response) {
  const userId = actorUserId(req);
  const empresaId = actorEmpresaId(req);

  const parsed = crmInstanceCreateSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const { nombre_instancia, evolution_base_url, evolution_api_key } = parsed.data;

  // Check if instance name already exists for this empresa
  const existing = await prisma.$queryRawUnsafe<any[]>(
    `SELECT id FROM crm_instancias WHERE nombre_instancia = $1 AND empresa_id = $2 LIMIT 1`,
    nombre_instancia,
    empresaId
  );

  if (existing.length > 0) {
    throw new ApiError(409, 'Instance name already exists');
  }

  // Deactivate other instances for this user
  await prisma.$executeRawUnsafe(
    `UPDATE crm_instancias SET is_active = FALSE WHERE user_id = $1`,
    userId
  );

  // Create new instance
  const instances = await prisma.$queryRawUnsafe<any[]>(
    `INSERT INTO crm_instancias (empresa_id, user_id, nombre_instancia, evolution_base_url, evolution_api_key, is_active)
     VALUES ($1, $2, $3, $4, $5, TRUE)
     RETURNING id, empresa_id, user_id, nombre_instancia, evolution_base_url, is_active, created_at, updated_at`,
    empresaId,
    userId,
    nombre_instancia,
    evolution_base_url,
    evolution_api_key
  );

  res.status(201).json({ item: instances[0] });
}

// ======================================
// PATCH /api/crm/instances/:id - Update instance
// ======================================
export async function updateInstance(req: Request, res: Response) {
  const userId = actorUserId(req);
  const empresaId = actorEmpresaId(req);
  const { id } = req.params;

  const parsed = crmInstanceUpdateSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  // Verify ownership
  const existing = await prisma.$queryRawUnsafe<any[]>(
    `SELECT id FROM crm_instancias WHERE id = $1 AND user_id = $2 AND empresa_id = $3 LIMIT 1`,
    id,
    userId,
    empresaId
  );

  if (existing.length === 0) {
    throw new ApiError(404, 'Instance not found');
  }

  const updates: string[] = [];
  const values: any[] = [];
  let paramIndex = 1;

  if (parsed.data.nombre_instancia !== undefined) {
    updates.push(`nombre_instancia = $${paramIndex++}`);
    values.push(parsed.data.nombre_instancia);
  }
  if (parsed.data.evolution_base_url !== undefined) {
    updates.push(`evolution_base_url = $${paramIndex++}`);
    values.push(parsed.data.evolution_base_url);
  }
  if (parsed.data.evolution_api_key !== undefined) {
    updates.push(`evolution_api_key = $${paramIndex++}`);
    values.push(parsed.data.evolution_api_key);
  }
  if (parsed.data.is_active !== undefined) {
    // If activating, deactivate others first
    if (parsed.data.is_active) {
      await prisma.$executeRawUnsafe(
        `UPDATE crm_instancias SET is_active = FALSE WHERE user_id = $1 AND id != $2`,
        userId,
        id
      );
    }
    updates.push(`is_active = $${paramIndex++}`);
    values.push(parsed.data.is_active);
  }

  if (updates.length === 0) {
    throw new ApiError(400, 'No fields to update');
  }

  updates.push(`updated_at = NOW()`);
  values.push(id, userId, empresaId);

  const instances = await prisma.$queryRawUnsafe<any[]>(
    `UPDATE crm_instancias 
     SET ${updates.join(', ')}
     WHERE id = $${paramIndex} AND user_id = $${paramIndex + 1} AND empresa_id = $${paramIndex + 2}
     RETURNING id, empresa_id, user_id, nombre_instancia, evolution_base_url, is_active, created_at, updated_at`,
    ...values
  );

  res.json({ item: instances[0] });
}

// ======================================
// DELETE /api/crm/instances/:id - Delete instance
// ======================================
export async function deleteInstance(req: Request, res: Response) {
  const userId = actorUserId(req);
  const empresaId = actorEmpresaId(req);
  const { id } = req.params;

  // Check if instance has chats
  const chats = await prisma.$queryRawUnsafe<any[]>(
    `SELECT COUNT(*) as count FROM crm_chats WHERE instancia_id = $1`,
    id
  );

  if (chats[0]?.count > 0) {
    throw new ApiError(409, 'Cannot delete instance with existing chats. Transfer or delete chats first.');
  }

  // Delete instance
  await prisma.$executeRawUnsafe(
    `DELETE FROM crm_instancias WHERE id = $1 AND user_id = $2 AND empresa_id = $3`,
    id,
    userId,
    empresaId
  );

  res.json({ success: true });
}

// ======================================
// POST /api/crm/instances/test-connection - Test connection
// ======================================
export async function testConnection(req: Request, res: Response) {
  const parsed = crmInstanceTestConnectionSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const { evolution_base_url, evolution_api_key, nombre_instancia } = parsed.data;

  try {
    // Test connection with a simple request to the Evolution API
    const testUrl = `${evolution_base_url}/instance/fetchInstances`;
    
    const response = await axios.get(testUrl, {
      headers: {
        'apikey': evolution_api_key,
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });

    // Check if the specified instance exists in the response
    const instances = response.data;
    const instanceExists = Array.isArray(instances) 
      ? instances.some((inst: any) => inst.instance?.instanceName === nombre_instancia)
      : false;

    res.json({ 
      success: true, 
      message: 'Connection successful',
      instanceExists,
      instanceCount: Array.isArray(instances) ? instances.length : 0
    });
  } catch (error: any) {
    const message = error.response?.data?.message || error.message || 'Unknown error';
    throw new ApiError(400, `Connection failed: ${message}`);
  }
}

// ======================================
// POST /api/crm/chats/:chatId/transfer - Transfer chat to another user
// ======================================
export async function transferChat(req: Request, res: Response) {
  const userId = actorUserId(req);
  const empresaId = actorEmpresaId(req);
  const { chatId } = req.params;

  const parsed = crmChatTransferSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const { toUserId, toInstanceId, notes } = parsed.data;

  // Start transaction
  await prisma.$transaction(async (tx) => {
    // 1. Verify chat belongs to current user's instance
    const chats = await tx.$queryRawUnsafe<any[]>(
      `SELECT c.id, c.instancia_id, c.asignado_a_user_id, i.user_id as instance_owner
       FROM crm_chats c
       LEFT JOIN crm_instancias i ON i.id = c.instancia_id
       WHERE c.id = $1 AND c.empresa_id = $2
       LIMIT 1`,
      chatId,
      empresaId
    );

    const chat = chats[0];
    if (!chat) {
      throw new ApiError(404, 'Chat not found');
    }

    // Verify current user has access to this chat
    if (chat.asignado_a_user_id !== userId && chat.instance_owner !== userId) {
      throw new ApiError(403, 'You do not have permission to transfer this chat');
    }

    // 2. Get target user's active instance (or use provided instanceId)
    let targetInstanceId = toInstanceId;
    
    if (!targetInstanceId) {
      const targetInstances = await tx.$queryRawUnsafe<any[]>(
        `SELECT id FROM crm_instancias 
         WHERE user_id = $1 AND empresa_id = $2 AND is_active = TRUE
         LIMIT 1`,
        toUserId,
        empresaId
      );

      if (targetInstances.length === 0) {
        throw new ApiError(400, 'Target user does not have an active instance');
      }

      targetInstanceId = targetInstances[0].id;
    } else {
      // Verify target instance belongs to target user
      const targetInstances = await tx.$queryRawUnsafe<any[]>(
        `SELECT id FROM crm_instancias 
         WHERE id = $1 AND user_id = $2 AND empresa_id = $3
         LIMIT 1`,
        targetInstanceId,
        toUserId,
        empresaId
      );

      if (targetInstances.length === 0) {
        throw new ApiError(400, 'Target instance does not belong to target user');
      }
    }

    // 3. Update chat
    await tx.$executeRawUnsafe(
      `UPDATE crm_chats 
       SET 
         instancia_id = $1,
         asignado_a_user_id = $2,
         updated_at = NOW()
       WHERE id = $3`,
      targetInstanceId,
      toUserId,
      chatId
    );

    // 4. Update messages to new instance (for audit purposes)
    await tx.$executeRawUnsafe(
      `UPDATE crm_messages 
       SET instancia_id = $1
       WHERE chat_id = $2`,
      targetInstanceId,
      chatId
    );

    // 5. Log transfer event
    await tx.$executeRawUnsafe(
      `INSERT INTO crm_chat_transfer_events 
       (chat_id, from_user_id, to_user_id, from_instancia_id, to_instancia_id, notes)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      chatId,
      userId,
      toUserId,
      chat.instancia_id,
      targetInstanceId,
      notes || null
    );
  });

  // Fetch updated chat
  const updatedChats = await prisma.$queryRawUnsafe<any[]>(
    `SELECT * FROM crm_chats WHERE id = $1 LIMIT 1`,
    chatId
  );

  res.json({ item: updatedChats[0], success: true });
}

// ======================================
// GET /api/crm/users - List users for transfer dropdown
// ======================================
export async function listUsersForTransfer(req: Request, res: Response) {
  const empresaId = actorEmpresaId(req);
  const currentUserId = actorUserId(req);

  // Get all users in the same empresa who have an active CRM instance
  const users = await prisma.$queryRawUnsafe<any[]>(
    `SELECT DISTINCT 
       u.id,
       u.username,
       u.email,
       i.id as instance_id,
       i.nombre_instancia
     FROM users u
     INNER JOIN crm_instancias i ON i.user_id = u.id AND i.is_active = TRUE
     WHERE u.empresa_id = $1 AND u.id != $2
     ORDER BY u.username`,
    empresaId,
    currentUserId
  );

  res.json({ items: users });
}
