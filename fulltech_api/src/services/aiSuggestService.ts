import axios from 'axios';

type Tone = 'Ejecutivo' | 'Cercano' | 'Formal';

export type AiSuggestionItem = {
  id: string;
  text: string;
  confidence?: number;
  tags?: string[];
};

export class AiSuggestService {
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

  async suggest(params: {
    customerMessageText: string;
    systemPrompt?: string | null;
    tone?: Tone | null;
    rules?: string | null;
    businessData?: Record<string, any> | null;
    maxSuggestions?: number;
  }): Promise<{ suggestions: AiSuggestionItem[]; usedKnowledge: string[] }> {
    if (!this.apiKey) {
      return { suggestions: [], usedKnowledge: [] };
    }

    const maxSuggestions = params.maxSuggestions ?? 3;

    const prompt = {
      systemPrompt:
        params.systemPrompt?.trim() ||
        'Eres un asistente de ventas y soporte por WhatsApp. Responde con profesionalidad y claridad.',
      tone: params.tone ?? 'Ejecutivo',
      rules:
        params.rules?.trim() ||
        'No inventes. No prometas tiempos exactos. Responde corto y accionable. Si falta info, haz 1 pregunta.',
      businessData: params.businessData ?? {},
    };

    const instruction = `Genera de 1 a ${maxSuggestions} sugerencias cortas y útiles para responder al cliente.
Devuelve SOLO JSON con esta forma exacta:
{
  "suggestions": [
    { "text": "...", "confidence": 0.0, "tags": ["..."] }
  ]
}

Tono: ${prompt.tone}
Reglas:
${prompt.rules}

Datos del negocio (puede estar vacío):
${JSON.stringify(prompt.businessData).slice(0, 4000)}

Mensaje del cliente:
${params.customerMessageText}`;

    const response = await axios.post(
      `${this.baseUrl}/chat/completions`,
      {
        model: this.model,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: prompt.systemPrompt },
          { role: 'user', content: instruction },
        ],
        max_tokens: 450,
        temperature: 0.4,
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
      return { suggestions: [], usedKnowledge: [] };
    }

    const parsed = this.safeJsonParse<{ suggestions?: any[] }>(content);

    const suggestions: AiSuggestionItem[] = (parsed.suggestions ?? [])
      .map((s) => ({
        id: '',
        text: typeof s?.text === 'string' ? s.text : '',
        confidence: typeof s?.confidence === 'number' ? s.confidence : undefined,
        tags: Array.isArray(s?.tags) ? s.tags.map(String) : undefined,
      }))
      .filter((s) => s.text.trim().length > 0)
      .slice(0, maxSuggestions);

    return { suggestions, usedKnowledge: ['llm'] };
  }
}
