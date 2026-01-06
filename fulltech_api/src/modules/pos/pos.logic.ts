export type ProductStockRule = {
  allow_negative_stock: boolean;
  stock_qty: number;
};

export function wouldBlockStock(rule: ProductStockRule, qtyOut: number): boolean {
  if (qtyOut <= 0) return false;
  if (rule.allow_negative_stock) return false;
  return rule.stock_qty - qtyOut < 0;
}

export function suggestReorderQty(opts: {
  stockQty: number;
  minStock: number;
  maxStock: number;
}): number {
  const stockQty = Number(opts.stockQty) || 0;
  const minStock = Number(opts.minStock) || 0;
  const maxStock = Number(opts.maxStock) || 0;

  const target = maxStock > 0 ? maxStock : minStock;
  const raw = target - stockQty;
  if (!Number.isFinite(raw) || raw <= 0) return 0;
  return raw;
}

export function parseDateOrNull(value: unknown): Date | null {
  if (typeof value !== 'string' || value.trim().length === 0) return null;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return d;
}

export function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}
