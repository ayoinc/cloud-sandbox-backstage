/** The optional parts of the store. */
export interface Features {
  /** Admin API to create, change and delete products. */
  productManagement: boolean;
  /** Payment step at checkout. */
  payments: boolean;
  /** Text search in the product catalogue. */
  search: boolean;
  /** Customer reviews and ratings. */
  reviews: boolean;
  /** Stock levels: orders reduce them and cannot exceed them. */
  inventory: boolean;
  /** Sales figures for the admin page. */
  analytics: boolean;
  /** Cache of catalogue reads in Redis. */
  caching: boolean;
}

// Chosen when the store was created. Change a value here to change the default
// everywhere, or set FEATURE_<NAME>=true|false to change it in one environment.
export const featureDefaults: Features = {
  productManagement: ${{ 'true' if values.enableCMS else 'false' }},
  payments: ${{ 'true' if values.enablePayments else 'false' }},
  search: ${{ 'true' if values.enableSearch else 'false' }},
  reviews: ${{ 'true' if values.enableReviews else 'false' }},
  inventory: ${{ 'true' if values.enableInventory else 'false' }},
  analytics: ${{ 'true' if values.enableAnalytics else 'false' }},
  caching: ${{ 'true' if values.enableCaching else 'false' }},
};
