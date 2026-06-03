export interface BatchItem {
  weightKg: number;
  category?: string;
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

export function computeByCategory(items: BatchItem[]): Record<string, number> {
  const result: Record<string, number> = {};
  for (const item of items) {
    const cat = item.category?.trim() || 'other';
    result[cat] = (result[cat] ?? 0) + (item.weightKg ?? 0);
  }
  // remove zero-kg entries
  for (const key of Object.keys(result)) {
    if (result[key] === 0) delete result[key];
  }
  return result;
}

export function formatKg(kg: number): string {
  return kg.toFixed(1);
}
