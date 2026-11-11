import { randomUUID } from 'node:crypto';

export interface Charge {
  orderId: string;
  amountCents: number;
  /** What the checkout form collected: a card token of the payment gateway. */
  paymentToken: string;
}

export type ChargeResult = { status: 'succeeded'; reference: string } | { status: 'declined'; reason: string };

/**
 * Takes the payment of an order. Implement this interface for your payment
 * gateway and pass the implementation to createApp in index.ts.
 */
export interface PaymentProvider {
  charge(charge: Charge): Promise<ChargeResult>;
}

/**
 * Stands in for a payment gateway: no money moves. It accepts every token
 * except "tok_declined", which lets you try a refused payment.
 */
export class SandboxPaymentProvider implements PaymentProvider {
  async charge({ paymentToken }: Charge): Promise<ChargeResult> {
    if (paymentToken === 'tok_declined') {
      return { status: 'declined', reason: 'The card was declined.' };
    }
    return { status: 'succeeded', reference: `sandbox_${randomUUID()}` };
  }
}
