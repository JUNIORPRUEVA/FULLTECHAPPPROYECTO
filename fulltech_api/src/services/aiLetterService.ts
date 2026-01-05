import axios from 'axios';

type Tone = 'Ejecutivo' | 'Cercano' | 'Formal';

export type GenerateLetterInput = {
  systemPrompt?: string | null;
  tone?: Tone | null;
  rules?: string | null;
  companyProfile: Record<string, any>;
  letterType: string;
  quotation?: Record<string, any> | null;
  manualCustomer?: {
    name: string;
    phone?: string | null;
    email?: string | null;
  } | null;
  manualContext?: string | null;
  action?: 'generate' | 'improve' | 'more_formal' | 'shorter';
  subject?: string | null;
  body?: string | null;
};

export class AiLetterService {
  private apiKey: string;
  private baseUrl: string;
  private model: string;

  constructor() {
    this.apiKey =
      process.env.OPENAI_API_KEY ||
      process.env.APIKEY_CHATGPT ||
      process.env.OPENAIKEY ||
      process.env.AI_API_KEY ||
      '';
    this.baseUrl = (process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1').replace(/\/+$/, '');
    this.model = process.env.OPENAI_MODEL || 'gpt-4o-mini';
  }

  get isEnabled() {
    return Boolean(this.apiKey);
  }

  private safeJsonParse<T>(text: string): T {
    try {
      return JSON.parse(text) as T;
    } catch {
      const start = text.indexOf('{');
      const end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        const slice = text.slice(start, end + 1);
        return JSON.parse(slice) as T;
      }
      throw new Error('Invalid JSON returned by AI');
    }
  }

  async generateLetter(input: GenerateLetterInput): Promise<{ subject: string; body: string }> {
    if (!this.apiKey) {
      throw new Error('AI is not enabled (missing API key)');
    }

    const systemPrompt =
      input.systemPrompt?.trim() ||
      'Eres un asistente de redacción corporativa. Escribes cartas profesionales en español (República Dominicana).';

    const tone = input.tone ?? 'Formal';

    const rules =
      input.rules?.trim() ||
      'No inventes datos. Si falta información, redacta genérico sin afirmar hechos falsos. Evita promesas de tiempos exactos.';

    const action = input.action ?? 'generate';

    const instruction = `Tarea: ${action}

Devuelve SOLO JSON con esta forma exacta:
{
  "subject": "...",
  "body": "..."
}

Requisitos del texto:
- Español formal profesional (RD), claro y directo.
- No inventes datos. Si falta info, redacta genérico.
- Estructura sugerida:
  1) Saludo
  2) Cuerpo según el tipo de carta
  3) Cierre con agradecimiento
  4) Firma (solo nombre de empresa)

Tono: ${tone}
Reglas:
${rules}

Tipo de carta:
${input.letterType}

Perfil empresa (header/footer fijo, NO editable):
${JSON.stringify(input.companyProfile).slice(0, 6000)}

Cliente (si aplica):
${JSON.stringify(input.manualCustomer ?? null).slice(0, 2000)}

Cotización (si existe):
${JSON.stringify(input.quotation ?? null).slice(0, 6000)}

Contexto adicional del usuario:
${(input.manualContext ?? '').slice(0, 4000)}

Texto actual (si aplica a mejora/variantes):
Asunto: ${(input.subject ?? '').slice(0, 400)}
Cuerpo: ${(input.body ?? '').slice(0, 12000)}`;

    const response = await axios.post(
      `${this.baseUrl}/chat/completions`,
      {
        model: this.model,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: instruction },
        ],
        max_tokens: 900,
        temperature: 0.35,
      },
      {
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
      },
    );

    const content = response.data?.choices?.[0]?.message?.content;
    if (typeof content !== 'string' || content.trim().length === 0) {
      throw new Error('Empty AI response');
    }

    const parsed = this.safeJsonParse<{ subject?: any; body?: any }>(content);

    const subject = typeof parsed.subject === 'string' ? parsed.subject.trim() : '';
    const body = typeof parsed.body === 'string' ? parsed.body.trim() : '';

    if (!subject || !body) {
      throw new Error('AI returned invalid letter payload');
    }

    return { subject, body };
  }
}
