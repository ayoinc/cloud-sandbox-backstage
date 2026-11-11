import type { PresetId } from './palette.generated';

/** Corner radii in px for one shape family. */
export interface ShapeScale {
  none: number;
  control: number;
  card: number;
  cardLarge: number;
  dialog: number;
  full: number;
}

const soft: ShapeScale = {
  none: 0,
  control: 4,
  card: 8,
  cardLarge: 12,
  dialog: 12,
  full: 9999,
};
const square: ShapeScale = {
  ...soft,
  control: 0,
  card: 0,
  cardLarge: 0,
  dialog: 0,
};
const round: ShapeScale = {
  ...soft,
  control: 8,
  card: 12,
  cardLarge: 16,
  dialog: 28,
};

/** What an administrator sees when choosing a theme preset. */
export interface BrandPreset {
  title: string;
  description: string;
  shape: ShapeScale;
}

/**
 * The theme presets. Colours come from the seeds in
 * scripts/generate-palette.mjs; this is the part a person reads.
 */
export const presets: Record<PresetId, BrandPreset> = {
  neutral: {
    title: 'Neutral',
    description:
      'Slate and charcoal. The default, with no identity of its own.',
    shape: soft,
  },
  harbour: {
    title: 'Harbour',
    description: 'Deep blue actions on a dark teal sidebar.',
    shape: soft,
  },
  forest: {
    title: 'Forest',
    description: 'Green actions on a dark evergreen sidebar.',
    shape: soft,
  },
  plum: {
    title: 'Plum',
    description: 'Purple actions on a dark aubergine sidebar.',
    shape: soft,
  },
  ember: {
    title: 'Ember',
    description: 'Burnt orange actions on a dark brown sidebar.',
    shape: soft,
  },
  civic: {
    title: 'Civic',
    description: 'Public-service blue on black, with square corners.',
    shape: square,
  },
  baseline: {
    title: 'Baseline',
    description: 'Material purple with generously rounded corners.',
    shape: round,
  },
};
