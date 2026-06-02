import { computeTotals, formatKg } from '../computations';

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
