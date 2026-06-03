import { computeByCategory, computeTotals, formatKg } from '../computations';

describe('computeTotals', () => {
  it('sums weightKg and derives meals + co2e at 2.5×', () => {
    const result = computeTotals([{ weightKg: 4 }, { weightKg: 6 }]);
    expect(result.totalKg).toBeCloseTo(10);
    expect(result.totalMeals).toBeCloseTo(25);
    expect(result.totalCo2e).toBeCloseTo(25);
  });

  it('handles empty array', () => {
    const result = computeTotals([]);
    expect(result.totalKg).toBe(0);
    expect(result.totalMeals).toBe(0);
    expect(result.totalCo2e).toBe(0);
  });

  it('treats undefined weightKg as 0', () => {
    const result = computeTotals([{ weightKg: undefined as unknown as number }]);
    expect(result.totalKg).toBe(0);
  });
});

describe('formatKg', () => {
  it('formats to one decimal place', () => {
    expect(formatKg(8.5)).toBe('8.5');
    expect(formatKg(10)).toBe('10.0');
    expect(formatKg(0)).toBe('0.0');
  });
});

describe('computeByCategory', () => {
  it('sums weights by known category', () => {
    const result = computeByCategory([
      { weightKg: 3, category: 'bakery' },
      { weightKg: 2, category: 'bakery' },
      { weightKg: 5, category: 'produce' },
    ]);
    expect(result['bakery']).toBeCloseTo(5);
    expect(result['produce']).toBeCloseTo(5);
  });

  it('maps unknown category to other', () => {
    const result = computeByCategory([
      { weightKg: 4, category: 'mystery_food' },
    ]);
    expect(result['other']).toBeCloseTo(4);
    expect(result['mystery_food']).toBeUndefined();
  });

  it('remaps legacy "protein" to "meat"', () => {
    const result = computeByCategory([{ weightKg: 3, category: 'protein' }]);
    expect(result['meat']).toBeCloseTo(3);
    expect(result['protein']).toBeUndefined();
  });

  it('remaps legacy "prepared" to "other"', () => {
    const result = computeByCategory([{ weightKg: 2, category: 'prepared' }]);
    expect(result['other']).toBeCloseTo(2);
    expect(result['prepared']).toBeUndefined();
  });

  it('maps missing category to other', () => {
    const result = computeByCategory([{ weightKg: 2 }]);
    expect(result['other']).toBeCloseTo(2);
  });

  it('returns empty object for empty items', () => {
    expect(computeByCategory([])).toEqual({});
  });

  it('omits zero-kg entries', () => {
    const result = computeByCategory([
      { weightKg: 0, category: 'bakery' },
      { weightKg: 1, category: 'dairy' },
    ]);
    expect(result['bakery']).toBeUndefined();
    expect(result['dairy']).toBeCloseTo(1);
  });
});
