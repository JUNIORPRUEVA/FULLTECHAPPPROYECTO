import type { Request, Response } from 'express';
import { randomUUID } from 'crypto';

import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { AiSuggestService } from '../../services/aiSuggestService';
import { AiLetterService } from '../../services/aiLetterService';
import { aiGenerateLetterSchema, aiSettingsUpsertSchema, aiSuggestSchema } from './ai.schema';

let aiSettingsExistsCache: boolean | null = null;
let aiSettingsExistsAtMs = 0;
async function aiSettingsTableExists(): Promise<boolean> {
  const now = Date.now();
  if (aiSettingsExistsCache != null && now - aiSettingsExistsAtMs < 60_000) {
    return aiSettingsExistsCache;
  }

  try {
    const rows = await prisma.$queryRawUnsafe<{ count: number }[]>(
      `SELECT COUNT(*)::int as count
       FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = 'ai_settings'`,
    );
    const exists = Number(rows?.[0]?.count ?? 0) > 0;
    aiSettingsExistsCache = exists;
    aiSettingsExistsAtMs = now;
    return exists;
  } catch {
    aiSettingsExistsCache = false;
    aiSettingsExistsAtMs = now;
    return false;
  }
}

let aiSuggestionsExistsCache: boolean | null = null;
let aiSuggestionsExistsAtMs = 0;
async function aiSuggestionsTableExists(): Promise<boolean> {
  const now = Date.now();
  if (aiSuggestionsExistsCache != null && now - aiSuggestionsExistsAtMs < 60_000) {
    return aiSuggestionsExistsCache;
  }

  try {
    const rows = await prisma.$queryRawUnsafe<{ count: number }[]>(
      `SELECT COUNT(*)::int as count
       FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = 'ai_suggestions'`,
    );
    const exists = Number(rows?.[0]?.count ?? 0) > 0;
    aiSuggestionsExistsCache = exists;
    aiSuggestionsExistsAtMs = now;
    return exists;
  } catch {
    aiSuggestionsExistsCache = false;
    aiSuggestionsExistsAtMs = now;
    return false;
  }
}

function normalizeText(input: string): string {
  return input
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function parseKeywords(v: any): string[] {
  if (!v) return [];
  const s = String(v);
  return s
    .split(',')
    .map((x) => normalizeText(x))
    .map((x) => x.trim())
    .filter((x) => x.length > 0);
}

async function loadSettings() {
  if (!(await aiSettingsTableExists())) {
    return {
      enabled: true,
      quickRepliesEnabled: true,
      systemPrompt: null,
      tone: 'Ejecutivo',
      rules: null,
      businessData: {},
      promptVersion: 1,
      updatedAt: null,
    };
  }

  const rows = await prisma.$queryRawUnsafe<any[]>(
    `SELECT id, enabled, quick_replies_enabled, system_prompt, tone, rules, business_data, prompt_version, updated_at
     FROM ai_settings
     WHERE id = 1`,
  );
  const row = rows?.[0];
  if (!row) {
    return {
      enabled: true,
      quickRepliesEnabled: true,
      systemPrompt: null,
      tone: 'Ejecutivo',
      rules: null,
      businessData: {},
      promptVersion: 1,
      updatedAt: null,
    };
  }
  return {
    enabled: Boolean(row.enabled),
    quickRepliesEnabled: Boolean(row.quick_replies_enabled),
    systemPrompt: row.system_prompt ?? null,
    tone: row.tone ?? 'Ejecutivo',
    rules: row.rules ?? null,
    businessData: row.business_data ?? {},
    promptVersion: Number(row.prompt_version ?? 1),
    updatedAt: row.updated_at ?? null,
  };
}

export async function generateLetter(req: Request, res: Response) {
  const s = await loadSettings();
  const body = aiGenerateLetterSchema.parse(req.body);

  const llm = new AiLetterService();
  if (!llm.isEnabled) {
    throw new ApiError(400, 'AI is not enabled');
  }

  const out = await llm.generateLetter({
    systemPrompt: s.systemPrompt,
    tone: body.tone ?? s.tone,
    rules: s.rules,
    companyProfile: body.companyProfile,
    letterType: body.letterType,
    quotation: body.quotation ?? null,
    manualCustomer: body.manualCustomer ?? null,
    manualContext: body.manualContext ?? null,
    action: body.action,
    subject: body.subject ?? null,
    body: body.body ?? null,
  });

  res.json(out);
}

export async function getAiSettingsPublic(_req: Request, res: Response) {
  const s = await loadSettings();
  res.json({
    enabled: s.enabled,
    quickRepliesEnabled: s.quickRepliesEnabled,
    tone: s.tone,
    promptVersion: s.promptVersion,
    updatedAt: s.updatedAt,
  });
}

export async function getAiSettings(_req: Request, res: Response) {
  const s = await loadSettings();
  res.json({
    enabled: s.enabled,
    quickRepliesEnabled: s.quickRepliesEnabled,
    systemPrompt: s.systemPrompt,
    tone: s.tone,
    rules: s.rules,
    businessData: s.businessData,
    promptVersion: s.promptVersion,
    updatedAt: s.updatedAt,
  });
}

export async function patchAiSettings(req: Request, res: Response) {
  if (!(await aiSettingsTableExists())) {
    throw new ApiError(
      503,
      'AI settings are not initialized (missing ai_settings table). Run the AI settings SQL migration first.',
    );
  }

  const parsed = aiSettingsUpsertSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const current = await loadSettings();

  const enabled = typeof parsed.data.enabled === 'boolean' ? parsed.data.enabled : current.enabled;
  const quickRepliesEnabled =
    typeof parsed.data.quickRepliesEnabled === 'boolean'
      ? parsed.data.quickRepliesEnabled
      : current.quickRepliesEnabled;
  const systemPrompt =
    typeof parsed.data.systemPrompt !== 'undefined' ? parsed.data.systemPrompt : current.systemPrompt;
  const tone = typeof parsed.data.tone !== 'undefined' ? parsed.data.tone : current.tone;
  const rules = typeof parsed.data.rules !== 'undefined' ? parsed.data.rules : current.rules;
  const businessData =
    typeof parsed.data.businessData !== 'undefined' ? parsed.data.businessData : current.businessData;

  const nextPromptVersion = current.promptVersion + 1;

  await prisma.$executeRawUnsafe(
    `
    INSERT INTO ai_settings (id, enabled, quick_replies_enabled, system_prompt, tone, rules, business_data, prompt_version, updated_at)
    VALUES (1, $1::boolean, $2::boolean, $3::text, $4::text, $5::text, $6::jsonb, $7::int, now())
    ON CONFLICT (id) DO UPDATE SET
      enabled = EXCLUDED.enabled,
      quick_replies_enabled = EXCLUDED.quick_replies_enabled,
      system_prompt = EXCLUDED.system_prompt,
      tone = EXCLUDED.tone,
      rules = EXCLUDED.rules,
      business_data = EXCLUDED.business_data,
      prompt_version = EXCLUDED.prompt_version,
      updated_at = now();
    `,
    enabled,
    quickRepliesEnabled,
    systemPrompt,
    tone,
    rules,
    JSON.stringify(businessData ?? {}),
    nextPromptVersion,
  );

  const updated = await loadSettings();
  res.json({
    enabled: updated.enabled,
    quickRepliesEnabled: updated.quickRepliesEnabled,
    systemPrompt: updated.systemPrompt,
    tone: updated.tone,
    rules: updated.rules,
    businessData: updated.businessData,
    promptVersion: updated.promptVersion,
    updatedAt: updated.updatedAt,
  });
}

export async function suggestAiReplies(req: Request, res: Response) {
  const parsed = aiSuggestSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const settings = await loadSettings();
  if (!settings.enabled) {
    res.json({ suggestions: [], usedKnowledge: [`promptVersion:${settings.promptVersion}`] });
    return;
  }

  const quickRepliesEnabled =
    settings.quickRepliesEnabled && (parsed.data.quickRepliesEnabled ?? true);

  const usedKnowledge: string[] = [`promptVersion:${settings.promptVersion}`];

  const messageNorm = normalizeText(parsed.data.customerMessageText);

  const suggestions: Array<{ id: string; text: string; confidence: number; tags: string[] }> = [];

  const canPersistSuggestions = await aiSuggestionsTableExists();

  if (quickRepliesEnabled) {
    const qrRows = await prisma.$queryRawUnsafe<any[]>(
      `
      SELECT id, title, content, keywords
      FROM quick_replies
      WHERE is_active = TRUE
      ORDER BY updated_at DESC, created_at DESC
      `,
    );

    const scored = qrRows
      .map((r) => {
        const keywords = parseKeywords(r.keywords);
        if (!keywords.length) return { row: r, score: 0 };
        let score = 0;
        for (const k of keywords) {
          if (k.length < 2) continue;
          if (messageNorm.includes(k)) score++;
        }
        return { row: r, score };
      })
      .filter((x) => x.score > 0)
      .sort((a, b) => b.score - a.score);

    for (const item of scored.slice(0, 3)) {
      const id = randomUUID();
      const tag = normalizeText(item.row.title).replace(/\s+/g, '_');
      const text = String(item.row.content ?? '').trim();
      if (!text) continue;
      suggestions.push({
        id,
        text,
        confidence: Math.min(0.95, 0.7 + item.score * 0.1),
        tags: [tag],
      });
      usedKnowledge.push(`quickReplies:${tag}`);

      // Persist suggestion for audit (optional).
      if (canPersistSuggestions) {
        await prisma.$executeRawUnsafe(
          `
          INSERT INTO ai_suggestions (id, chat_id, last_customer_message_id, customer_text, suggestion_text, used_knowledge)
          VALUES ($1::uuid, $2::uuid, $3::uuid, $4::text, $5::text, $6::jsonb)
          `,
          id,
          parsed.data.chatId ?? null,
          parsed.data.lastCustomerMessageId ?? null,
          parsed.data.customerMessageText,
          text,
          JSON.stringify(usedKnowledge),
        );
      }
    }
  }

  // If nothing matched, optionally ask LLM for 1-3 suggestions.
  if (!suggestions.length) {
    const llm = new AiSuggestService();
    if (llm.isEnabled) {
      const llmRes = await llm.suggest({
        customerMessageText: parsed.data.customerMessageText,
        systemPrompt: settings.systemPrompt,
        tone: settings.tone,
        rules: settings.rules,
        businessData: settings.businessData,
        maxSuggestions: 3,
      });

      for (const s of llmRes.suggestions.slice(0, 3)) {
        const id = randomUUID();
        suggestions.push({
          id,
          text: s.text.trim(),
          confidence: typeof s.confidence === 'number' ? s.confidence : 0.6,
          tags: Array.isArray(s.tags) ? s.tags.map(String) : [],
        });
        usedKnowledge.push(...llmRes.usedKnowledge);

        if (canPersistSuggestions) {
          await prisma.$executeRawUnsafe(
            `
            INSERT INTO ai_suggestions (id, chat_id, last_customer_message_id, customer_text, suggestion_text, used_knowledge)
            VALUES ($1::uuid, $2::uuid, $3::uuid, $4::text, $5::text, $6::jsonb)
            `,
            id,
            parsed.data.chatId ?? null,
            parsed.data.lastCustomerMessageId ?? null,
            parsed.data.customerMessageText,
            s.text.trim(),
            JSON.stringify(usedKnowledge),
          );
        }
      }
    } else {
      // Minimal fallback without LLM: 1 generic suggestion.
      const id = randomUUID();
      const text = '¡Gracias por tu mensaje! ¿Podrías confirmarme tu ubicación y el horario en que te conviene?';
      suggestions.push({ id, text, confidence: 0.35, tags: ['general'] });
      if (canPersistSuggestions) {
        await prisma.$executeRawUnsafe(
          `
          INSERT INTO ai_suggestions (id, chat_id, last_customer_message_id, customer_text, suggestion_text, used_knowledge)
          VALUES ($1::uuid, $2::uuid, $3::uuid, $4::text, $5::text, $6::jsonb)
          `,
          id,
          parsed.data.chatId ?? null,
          parsed.data.lastCustomerMessageId ?? null,
          parsed.data.customerMessageText,
          text,
          JSON.stringify(usedKnowledge),
        );
      }
    }
  }

  res.json({ suggestions, usedKnowledge });
}
