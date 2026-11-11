import { describe, expect, it } from 'vitest';
import { loadConfig } from '../src/config.js';
import { featureDefaults } from '../src/features.js';

describe('loadConfig', () => {
  it('uses the feature defaults', () => {
    expect(loadConfig({}).features).toEqual(featureDefaults);
  });

  it('lets FEATURE_ variables override the defaults', () => {
    const config = loadConfig({
      FEATURE_PRODUCT_MANAGEMENT: String(!featureDefaults.productManagement),
      FEATURE_REVIEWS: String(!featureDefaults.reviews),
    });

    expect(config.features).toEqual({
      ...featureDefaults,
      productManagement: !featureDefaults.productManagement,
      reviews: !featureDefaults.reviews,
    });
  });

  it('rejects invalid values', () => {
    expect(() => loadConfig({ FEATURE_SEARCH: 'maybe' })).toThrow('FEATURE_SEARCH');
    expect(() => loadConfig({ PORT: 'http' })).toThrow('PORT');
  });

  it('seeds sample data everywhere but in production', () => {
    expect(loadConfig({}).seedSampleData).toBe(true);
    expect(loadConfig({ NODE_ENV: 'production' }).seedSampleData).toBe(false);
    expect(loadConfig({ NODE_ENV: 'production', SEED_SAMPLE_DATA: 'true' }).seedSampleData).toBe(true);
  });
});
