import { brandTokensFor } from './brandTokens';
import { contrastRatio, blend } from './contrast';
import { contrastPairs } from './contrastPairs';
import { presetIds } from './palette.generated';

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

describe('brandTokensFor', () => {
  it('gives the default preset for an id it does not know', () => {
    expect(brandTokensFor('no-such-preset')).toBe(brandTokensFor(null));
    expect(brandTokensFor(null).preset).toBe(presetIds[0]);
  });

  const cases = presetIds.flatMap(preset =>
    (['light', 'dark'] as const).map(mode => [preset, mode] as const),
  );

  it.each(cases)(
    '%s %s meets WCAG 2.2 AA for every pairing',
    (preset, mode) => {
      const failures = contrastPairs(mode, preset)
        .filter(pair => pair.ratio < pair.minimum)
        .map(
          pair => `${pair.name}: ${pair.ratio.toFixed(2)} < ${pair.minimum}`,
        );
      expect(failures).toEqual([]);
    },
  );
});
