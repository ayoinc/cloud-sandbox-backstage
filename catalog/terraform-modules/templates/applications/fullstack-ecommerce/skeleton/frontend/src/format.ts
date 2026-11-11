const money = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' });

/** Formats an amount in cents, for example 1250 as $12.50. */
export function formatPrice(cents: number): string {
  return money.format(cents / 100);
}
