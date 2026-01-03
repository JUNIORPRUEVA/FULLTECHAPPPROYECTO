import axios from 'axios';

export interface IdentityData {
  fecha_nacimiento?: string; // ISO date format: YYYY-MM-DD
  lugar_nacimiento?: string;
  cedula_numero?: string;
  nombre_completo?: string;
  [key: string]: any;
}

class AiIdentityService {
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
    this.model = process.env.OPENAI_VISION_MODEL || process.env.OPENAI_MODEL || 'gpt-4o-mini';

    if (!this.apiKey) {
      console.warn('[AiIdentityService] No APIKEY_CHATGPT found in .env');
    }
  }

  private safeJsonParse<T>(text: string): T {
    try {
      return JSON.parse(text) as T;
    } catch {
      // Try to salvage JSON when model wraps it in text.
      const start = text.indexOf('{');
      const end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        const slice = text.slice(start, end + 1);
        return JSON.parse(slice) as T;
      }
      throw new Error('Invalid JSON returned by AI');
    }
  }

  /**
   * Extrae datos de una cédula dominicana usando IA.
   * @param imageUrlOrBuffer - URL de la imagen o Buffer del archivo
   * @returns Datos extraídos de la cédula
   */
  async extractDataFromCedula(
    imageUrlOrBuffer: string | Buffer,
  ): Promise<IdentityData> {
    try {
      // Si es un Buffer, convertir a base64
      let imageData: string;
      if (Buffer.isBuffer(imageUrlOrBuffer)) {
        imageData = imageUrlOrBuffer.toString('base64');
      } else {
        imageData = imageUrlOrBuffer;
      }

      const prompt = `You are an expert at reading Dominican identity cards (cédulas).
Extract ONLY these fields from the image:
- nombre_completo
- cedula_numero
- fecha_nacimiento (format YYYY-MM-DD)
- lugar_nacimiento

Return ONLY a valid JSON object with those fields.
If a field cannot be read, set it to null.`;

      const imageUrl = imageData.startsWith('http') ? imageData : `data:image/jpeg;base64,${imageData}`;

      const response = await axios.post(
        `${this.baseUrl}/chat/completions`,
        {
          model: this.model,
          response_format: { type: 'json_object' },
          messages: [
            {
              role: 'user',
              content: [
                { type: 'text', text: prompt },
                { type: 'image_url', image_url: { url: imageUrl } },
              ],
            },
          ],
          max_tokens: 500,
          temperature: 0,
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
        throw new Error('AI returned empty content');
      }

      const data = this.safeJsonParse<IdentityData>(content);

      // Validar y normalizar datos
      if (data.fecha_nacimiento) {
        data.fecha_nacimiento = this.normalizeFecha(data.fecha_nacimiento);
      }

      return data;
    } catch (error: any) {
      console.error('[AiIdentityService] Error extracting cedula data:', error.message);
      return {
        error: error.message || 'No se pudo procesar la imagen de la cédula',
      };
    }
  }

  /**
   * Normaliza una fecha a formato YYYY-MM-DD
   */
  private normalizeFecha(fecha: string): string {
    // Intentar reconocer diferentes formatos
    const formats = [
      /(\d{4})-(\d{2})-(\d{2})/, // YYYY-MM-DD
      /(\d{2})\/(\d{2})\/(\d{4})/, // DD/MM/YYYY
      /(\d{2})-(\d{2})-(\d{4})/, // DD-MM-YYYY
    ];

    for (const format of formats) {
      const match = fecha.match(format);
      if (match) {
        const [, p1, p2, p3] = match;
        // Si p3 es un año de 4 dígitos
        if (p3.length === 4) {
          // Formato DD/MM/YYYY → YYYY-MM-DD
          return `${p3}-${p2}-${p1}`;
        } else {
          // Formato YYYY-MM-DD
          return `${p1}-${p2}-${p3}`;
        }
      }
    }

    // Si no se puede parsear, devolver como está
    return fecha;
  }

  /**
   * Extrae datos de una licencia de conducir usando IA.
   * @param imageUrlOrBuffer - URL de la imagen o Buffer del archivo
   * @returns Datos extraídos de la licencia
   */
  async extractDataFromLicencia(
    imageUrlOrBuffer: string | Buffer,
  ): Promise<IdentityData> {
    try {
      // Si es un Buffer, convertir a base64
      let imageData: string;
      if (Buffer.isBuffer(imageUrlOrBuffer)) {
        imageData = imageUrlOrBuffer.toString('base64');
      } else {
        imageData = imageUrlOrBuffer;
      }

      const prompt = `You are an expert at reading driver's licenses (licencias de conducir).
Extract ONLY these fields from the image:
- numero_licencia (license number)
- fecha_vencimiento (expiration date, format YYYY-MM-DD)
- nombre_completo (full name)
- fecha_nacimiento (birth date, format YYYY-MM-DD)

Return ONLY a valid JSON object with those fields.
If a field cannot be read, set it to null.`;

      const imageUrl = imageData.startsWith('http') ? imageData : `data:image/jpeg;base64,${imageData}`;

      const response = await axios.post(
        `${this.baseUrl}/chat/completions`,
        {
          model: this.model,
          response_format: { type: 'json_object' },
          messages: [
            {
              role: 'user',
              content: [
                { type: 'text', text: prompt },
                { type: 'image_url', image_url: { url: imageUrl } },
              ],
            },
          ],
          max_tokens: 500,
          temperature: 0,
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
        throw new Error('AI returned empty content');
      }

      const data = this.safeJsonParse<IdentityData>(content);

      // Validar y normalizar fechas
      if (data.fecha_nacimiento) {
        data.fecha_nacimiento = this.normalizeFecha(data.fecha_nacimiento);
      }
      if (data.fecha_vencimiento) {
        data.fecha_vencimiento = this.normalizeFecha(data.fecha_vencimiento);
      }

      return data;
    } catch (error: any) {
      console.error('[AiIdentityService] Error extracting licencia data:', error.message);
      return {
        error: error.message || 'No se pudo procesar la imagen de la licencia',
      };
    }
  }

  /**
   * Calcula la edad a partir de fecha de nacimiento
   */
  calculateAge(fechaNacimiento: string): number {
    const today = new Date();
    const birthDate = new Date(fechaNacimiento);
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();

    if (
      monthDiff < 0 ||
      (monthDiff === 0 && today.getDate() < birthDate.getDate())
    ) {
      age--;
    }

    return age;
  }
}

export const aiIdentityService = new AiIdentityService();
