import { brandTokens } from './brandTokens';
import { contrastRatio, blend } from './contrast';
import { contrastPairs } from './contrastPairs';

describe('contrast helpers', () => {
  it('matches the WCAG reference values', () => {
    expect(contrastRatio('#000000', '#ffffff')).toBeCloseTo(21, 5);
    expect(contrastRatio('#ffffff', '#ffffff')).toBeCloseTo(1, 5);
    expect(contrastRatio('#767676', '#ffffff')).toBeCloseTo(4.54, 2);
  });

  it('blends a colour over a background', () => {
    expect(blend('#ffffff', '#000000', 0.5)).toBe('#808080');
  });
});

describe('brandTokens', () => {
  it('keeps the exact logo colours as identity colours', () => {
    expect(brandTokens.identity.soliriusBlue).toBe('#005399');
    expect(brandTokens.identity.replyTeal).toBe('#004149');
  });

  it('pins the light primary role to the logo blue', () => {
    expect(brandTokens.color.light.primary).toBe('#005399');
  });

  it.each(['light', 'dark'] as const)(
    'meets WCAG 2.2 AA for every %s pairing',
    mode => {
      const failures = contrastPairs(mode)
        .filter(pair => pair.ratio < pair.minimum)
        .map(
          pair => `${pair.name}: ${pair.ratio.toFixed(2)} < ${pair.minimum}`,
        );
      expect(failures).toEqual([]);
    },
  );
});
