/**
 * WCAG 2.2 relative luminance and contrast ratio helpers.
 * https://www.w3.org/TR/WCAG22/#dfn-contrast-ratio
 */

function parseHex(hex: string): [number, number, number] {
  const value = hex.replace('#', '');
  if (!/^[0-9a-f]{6}$/i.test(value)) {
    throw new Error(`Expected a 6-digit hex colour, received "${hex}"`);
  }
  return [0, 2, 4].map(i => parseInt(value.slice(i, i + 2), 16)) as [
    number,
    number,
    number,
  ];
}

function channel(value: number): number {
  const c = value / 255;
  return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}

/** WCAG relative luminance of a 6-digit hex colour. */
export function relativeLuminance(hex: string): number {
  const [r, g, b] = parseHex(hex);
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
}

/** WCAG contrast ratio between two 6-digit hex colours (1 to 21). */
export function contrastRatio(foreground: string, background: string): number {
  const a = relativeLuminance(foreground);
  const b = relativeLuminance(background);
  const [light, dark] = a > b ? [a, b] : [b, a];
  return (light + 0.05) / (dark + 0.05);
}

/**
 * Composites a foreground colour at the given opacity over an opaque
 * background, returning the resulting opaque hex colour.
 */
export function blend(
  foreground: string,
  background: string,
  opacity: number,
): string {
  const f = parseHex(foreground);
  const b = parseHex(background);
  return `#${f
    .map((c, i) => Math.round(c * opacity + b[i] * (1 - opacity)))
    .map(c => c.toString(16).padStart(2, '0'))
    .join('')}`;
}
