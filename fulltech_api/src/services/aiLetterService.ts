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

export type CartaAiContent = {
  greeting: string;
  bodyParagraphs: string[];
  closing: string;
  signatureSuggestion: string;
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
    // Responses API supports modern reasoning/text models; keep a safe default.
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

  private normalizeTextLine(s: string): string {
    return String(s ?? '')
      .replace(/\r\n/g, '\n')
      .replace(/\r/g, '\n')
      .replace(/\n{3,}/g, '\n\n')
      .trim();
  }

  private normalizeParagraphs(arr: unknown): string[] {
    if (!Array.isArray(arr)) return [];
    return arr
      .map((p) => (typeof p === 'string' ? this.normalizeTextLine(p) : ''))
      .filter((p) => p.length > 0)
      .slice(0, 12);
  }

  async generateCartaContent(input: {
    companyProfile: Record<string, any>;
    letterType: string;
    subject: string;
    userInstructions: string;
    customer: { name: string; phone?: string | null };
    quotationSummary?: Record<string, any> | null;
  }): Promise<CartaAiContent> {
    if (!this.apiKey) {
      throw new Error('AI is not enabled (missing API key)');
    }

    // Deterministic local smoke/testing.
    if (String(process.env.OPENAI_MOCK ?? '').trim() === 'true') {
      return {
        greeting: `Estimado/a ${input.customer.name}:`,
        bodyParagraphs: [
          'Reciba un cordial saludo.',
          `En atención a su solicitud, le compartimos la siguiente comunicación sobre: ${input.subject}.`,
          'Quedamos atentos a cualquier consulta adicional.',
        ],
        closing: 'Atentamente,',
        signatureSuggestion: String(input.companyProfile?.nombre ?? 'La Empresa'),
      };
    }

    const systemPrompt =
      'Eres un asistente de redacción corporativa. Escribes cartas profesionales en español (República Dominicana).';

    const guardrails = [
      'Mantén un tono profesional, claro y breve.',
      'No inventes datos. Usa únicamente información proporcionada (empresa/cliente/cotización).',
      'No hagas afirmaciones legales o garantías no confirmadas.',
      'Si falta un dato (ej. precios), no lo adivines; omite o redacta genérico.',
      'No uses markdown, tablas, viñetas con caracteres raros, ni fences de código.',
      'Devuelve texto en español natural.',
    ].join('\n- ');

    const instruction = `Redacta una carta en español (RD) con el siguiente contexto.

Devuelve SOLO JSON con esta forma exacta:
{
  "greeting": "...",
  "bodyParagraphs": ["...", "..."],
  "closing": "...",
  "signatureSuggestion": "..."
}

Reglas:
- ${guardrails}

Tipo de carta: ${input.letterType}
Asunto: ${input.subject}

Empresa (configuración):
${JSON.stringify(input.companyProfile).slice(0, 6000)}

Cliente:
${JSON.stringify(input.customer).slice(0, 2000)}

Instrucciones del usuario (obligatorias):
${String(input.userInstructions).slice(0, 6000)}

Cotización (si adjunta):
${JSON.stringify(input.quotationSummary ?? null).slice(0, 8000)}
`;

    // OpenAI Responses API
    const response = await axios.post(
      `${this.baseUrl}/responses`,
      {
        model: this.model,
        input: [
          {
            role: 'system',
            content: [{ type: 'input_text', text: systemPrompt }],
          },
          {
            role: 'user',
            content: [{ type: 'input_text', text: instruction }],
          },
        ],
        temperature: 0.35,
        max_output_tokens: 900,
      },
      {
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
      },
    );

    // Try common response shapes.
    const data = response.data;
    const content =
      (typeof data?.output_text === 'string' && data.output_text) ||
      (Array.isArray(data?.output)
        ? data.output
            .flatMap((o: any) => (Array.isArray(o?.content) ? o.content : []))
            .map((c: any) => (c?.type === 'output_text' ? c.text : ''))
            .filter(Boolean)
            .join('')
        : '');

    if (typeof content !== 'string' || content.trim().length === 0) {
      throw new Error('Empty AI response');
    }

    const parsed = this.safeJsonParse<{
      greeting?: unknown;
      bodyParagraphs?: unknown;
      closing?: unknown;
      signatureSuggestion?: unknown;
    }>(content);

    const greeting = typeof parsed.greeting === 'string' ? this.normalizeTextLine(parsed.greeting) : '';
    const closing = typeof parsed.closing === 'string' ? this.normalizeTextLine(parsed.closing) : '';
    const signatureSuggestion =
      typeof parsed.signatureSuggestion === 'string'
        ? this.normalizeTextLine(parsed.signatureSuggestion)
        : '';
    const bodyParagraphs = this.normalizeParagraphs(parsed.bodyParagraphs);

    if (!greeting || bodyParagraphs.length === 0 || !closing) {
      throw new Error('AI returned invalid carta payload');
    }

    return {
      greeting,
      bodyParagraphs,
      closing,
      signatureSuggestion: signatureSuggestion || String(input.companyProfile?.nombre ?? 'La Empresa'),
    };
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

    // Legacy endpoint (used by other modules): keep Chat Completions for now.
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
