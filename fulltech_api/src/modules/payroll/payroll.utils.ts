import type { PayrollHalf } from './payroll.schema';

export function computeQuincenaRange(year: number, month1to12: number, half: PayrollHalf) {
  const monthIndex = month1to12 - 1;
  const dateFrom = half === 'FIRST' ? new Date(Date.UTC(year, monthIndex, 1)) : new Date(Date.UTC(year, monthIndex, 16));
  const lastDay = new Date(Date.UTC(year, monthIndex + 1, 0)).getUTCDate();
  const dateToDay = half === 'FIRST' ? 15 : lastDay;
  const dateTo = new Date(Date.UTC(year, monthIndex, dateToDay));
  return { dateFrom, dateTo };
}

export function parseDateOnly(input: string): Date {
  // Accepts YYYY-MM-DD and converts to UTC date.
  const m = /^\d{4}-\d{2}-\d{2}$/.exec(input.trim());
  if (!m) {
    // fallback: let Date parse, but normalize to date-only
    const d = new Date(input);
    if (isNaN(d.getTime())) throw new Error('Invalid date');
    return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  }
  const [y, mo, da] = input.split('-').map((x) => parseInt(x, 10));
  return new Date(Date.UTC(y, mo - 1, da));
}

export function toMoney(value: any): number {
  const n = typeof value === 'number' ? value : Number(value);
  if (!isFinite(n)) return 0;
  return Math.round(n * 100) / 100;
}
