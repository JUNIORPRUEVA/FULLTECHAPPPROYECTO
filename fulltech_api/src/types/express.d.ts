import 'express';

declare global {
  namespace Express {
    interface Request {
      requestId?: string;
      user?: {
        userId: string;
        empresaId: string;
        role:
          | 'admin'
          | 'administrador'
          | 'vendedor'
          | 'tecnico'
          | 'tecnico_fijo'
          | 'contratista'
          | 'asistente_administrativo';
      };
      permissions?: string[];
    }
  }
}

export {};
