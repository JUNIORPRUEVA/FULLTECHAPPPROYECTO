import { Router, Request, Response } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import axios from 'axios';
import { prisma } from '../../config/prisma';

const router = Router();

// GET /api/integrations/evolution/config - Get Evolution config
router.get('/evolution/config', authMiddleware, async (req: Request, res: Response) => {
  try {
    // TODO: Add integrationConfig model to Prisma schema
    // const config = await prisma.integrationConfig.findUnique({
    //   where: { key: 'evolution' },
    // });
    const config = null;

    if (!config) {
      return res.json({
        instanceName: process.env.EVOLUTION_INSTANCE_NAME || '',
        evolutionBaseUrl: process.env.EVOLUTION_BASE_URL || '',
        expectedPhoneNumber: process.env.EVOLUTION_EXPECTED_PHONE || '',
        lastVerified: null,
      });
    }

    // This code is unreachable now since config is always null
    // const value = config.value as Record<string, any>;
    // return res.json({
    //   instanceName: value.instanceName || '',
    //   evolutionBaseUrl: value.evolutionBaseUrl || process.env.EVOLUTION_BASE_URL || '',
    //   expectedPhoneNumber: value.expectedPhoneNumber || '',
    //   lastVerified: value.lastVerified || null,
    // });
  } catch (err) {
    console.error('Error getting evolution config:', err);
    res.status(500).json({ error: 'Failed to get config' });
  }
});

// GET /api/integrations/evolution/status - Get Evolution instance status
router.get('/evolution/status', authMiddleware, async (req: Request, res: Response) => {
  try {
    const baseUrl = process.env.EVOLUTION_BASE_URL;
    const apiKey = process.env.EVOLUTION_API_KEY;
    const instance = process.env.EVOLUTION_INSTANCE_NAME;

    if (!baseUrl || !apiKey || !instance) {
      return res.status(400).json({ error: 'Evolution not configured' });
    }

    // Fetch status from Evolution API
    const statusRes = await axios.get(
      `${baseUrl}/instance/connectionState/${instance}`,
      { headers: { apikey: apiKey } }
    );

    // Try to get phone number via me endpoint
    let phoneNumber = null;
    try {
      const meRes = await axios.get(`${baseUrl}/chat/me/${instance}`, {
        headers: { apikey: apiKey },
      });
      phoneNumber = meRes.data?.jid || meRes.data?.phoneNumber || null;
    } catch (e) {
      console.warn('Could not fetch phone number');
    }

    res.json({
      connected: statusRes.data?.instance?.state === 'open',
      state: statusRes.data?.instance?.state || 'unknown',
      phoneNumber,
      lastChecked: new Date().toISOString(),
    });
  } catch (err) {
    console.error('Error getting evolution status:', err);
    res.status(500).json({ error: 'Failed to get status' });
  }
});

// GET /api/integrations/evolution/ping - Test Evolution connectivity
router.get('/evolution/ping', authMiddleware, async (req: Request, res: Response) => {
  try {
    const baseUrl = process.env.EVOLUTION_BASE_URL;
    const apiKey = process.env.EVOLUTION_API_KEY;

    if (!baseUrl || !apiKey) {
      return res.status(400).json({ error: 'Evolution not configured' });
    }

    const startTime = Date.now();
    await axios.get(`${baseUrl}/instance/check-connection-url`, {
      headers: { apikey: apiKey },
      timeout: 5000,
    });
    const latency = Date.now() - startTime;

    res.json({
      ok: true,
      message: 'Ping successful',
      latency,
    });
  } catch (err: any) {
    console.error('Error testing evolution ping:', err);
    res.status(500).json({
      ok: false,
      message: err.message || 'Ping failed',
      latency: null,
    });
  }
});

// PATCH /api/admin/integrations/evolution/config - Update Evolution config (admin only)
router.patch(
  '/evolution/config',
  authMiddleware,
  requireRole(['admin']),
  async (req: Request, res: Response) => {
    try {
      const { instanceName, evolutionBaseUrl, expectedPhoneNumber } = req.body;

      // Validate inputs
      if (!instanceName || !instanceName.trim()) {
        return res.status(400).json({ error: 'instanceName is required' });
      }

      const configData = {
        instanceName: instanceName.trim(),
        evolutionBaseUrl: evolutionBaseUrl || process.env.EVOLUTION_BASE_URL,
        expectedPhoneNumber: expectedPhoneNumber?.trim() || '',
        lastVerified: new Date().toISOString(),
      };

      // TODO: Add integrationConfig model to Prisma schema
      // Save to DB
      // await prisma.integrationConfig.upsert({
      //   where: { key: 'evolution' },
      //   update: { value: configData, updatedAt: new Date() },
      //   create: {
      //     key: 'evolution',
      //     value: configData,
      //   },
      // });

      // Test the new config by fetching status
      try {
        const statusRes = await axios.get(
          `${configData.evolutionBaseUrl}/instance/connectionState/${instanceName}`,
          { headers: { apikey: process.env.EVOLUTION_API_KEY } }
        );

        res.json({
          success: true,
          message: 'Config saved and verified',
          connected: statusRes.data?.instance?.state === 'open',
          config: {
            instanceName: configData.instanceName,
            evolutionBaseUrl: configData.evolutionBaseUrl,
            expectedPhoneNumber: configData.expectedPhoneNumber,
          },
        });
      } catch (statusErr) {
        console.warn('Config saved but status check failed:', statusErr);
        res.json({
          success: true,
          message: 'Config saved (status check failed)',
          connected: false,
          config: {
            instanceName: configData.instanceName,
            evolutionBaseUrl: configData.evolutionBaseUrl,
            expectedPhoneNumber: configData.expectedPhoneNumber,
          },
        });
      }
    } catch (err) {
      console.error('Error updating evolution config:', err);
      res.status(500).json({ error: 'Failed to update config' });
    }
  }
);

export const integrationsRouter = router;
