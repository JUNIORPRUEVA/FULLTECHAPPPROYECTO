import { Request, Response } from 'express';

import { prisma } from '../../../config/prisma';

export async function getUiSettings(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const userId = req.user!.userId;

  const rows = await prisma.$queryRaw<
    Array<{ large_screen_mode: boolean; hide_sidebar: boolean; scale: any }>
  >`
    SELECT large_screen_mode, hide_sidebar, scale
    FROM ui_settings
    WHERE empresa_id = ${empresaId}::uuid
      AND user_id = ${userId}::uuid
    LIMIT 1;
  `;

  const raw = rows[0];
  const item = raw
    ? {
        largeScreenMode: raw.large_screen_mode,
        hideSidebar: raw.hide_sidebar,
        scale: Number(raw.scale),
      }
    : { largeScreenMode: false, hideSidebar: false, scale: 1.0 };

  res.json({ item });
}

export async function updateUiSettings(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const userId = req.user!.userId;

  const body = req.body as {
    largeScreenMode?: boolean;
    hideSidebar?: boolean;
    scale?: number;
  };

  const largeScreenMode = body.largeScreenMode ?? false;
  const hideSidebar = body.hideSidebar ?? false;
  const scale =
    typeof body.scale === 'number' && body.scale >= 0.6 && body.scale <= 2.0
      ? body.scale
      : 1.0;

  await prisma.$executeRaw`
    INSERT INTO ui_settings(empresa_id, user_id, large_screen_mode, hide_sidebar, scale)
    VALUES (${empresaId}::uuid, ${userId}::uuid, ${largeScreenMode}::boolean, ${hideSidebar}::boolean, ${scale}::numeric)
    ON CONFLICT (empresa_id, user_id)
    DO UPDATE SET
      large_screen_mode = EXCLUDED.large_screen_mode,
      hide_sidebar = EXCLUDED.hide_sidebar,
      scale = EXCLUDED.scale,
      updated_at = now();
  `;

  res.json({ ok: true });
}
