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

// Canonical set mirrors the Dart FoodCategory enum exactly.
const VALID_CATEGORIES = new Set([
  'bakery', 'produce', 'dairy', 'meat', 'beverages', 'other',
]);

// Legacy / alternative spellings that must map to a canonical key.
const CATEGORY_REMAP: Record<string, string> = {
  protein: 'meat',
  prepared: 'other',
};

export function computeByCategory(items: BatchItem[]): Record<string, number> {
  const result: Record<string, number> = {};
  for (const item of items) {
    const raw = item.category?.trim().toLowerCase() || 'other';
    const remapped = CATEGORY_REMAP[raw] ?? raw;
    const cat = VALID_CATEGORIES.has(remapped) ? remapped : 'other';
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
