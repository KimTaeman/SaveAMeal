export interface BatchItem {
  weightKg: number;
}

export interface Totals {
  totalKg: number;
  totalMeals: number;
  totalCo2e: number;
}

export function computeTotals(items: BatchItem[]): Totals {
  const totalKg = items.reduce((sum, i) => sum + (i.weightKg ?? 0), 0);
  return {
    totalKg,
    totalMeals: totalKg * 2.5,
    totalCo2e: totalKg * 2.5,
  };
}

export function formatKg(kg: number): string {
  return kg.toFixed(1);
}
