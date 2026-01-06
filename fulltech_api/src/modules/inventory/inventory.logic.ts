import { ApiError } from '../../middleware/errorHandler';

export function parseDateOrNull(v?: string): Date | null {
  if (!v) return null;
  const d = new Date(v);
  return Number.isFinite(d.getTime()) ? d : null;
}

export function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

export function assertMinMax(minStock: number, maxStock?: number | null): void {
  const max = maxStock ?? 0;
  if (max > 0 && minStock > max) {
    throw new ApiError(400, 'min_stock cannot be greater than max_stock');
  }
}
