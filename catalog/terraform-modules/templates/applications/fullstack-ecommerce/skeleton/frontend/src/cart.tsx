import { createContext, type ReactNode, useContext, useEffect, useMemo, useState } from 'react';
import type { Product } from './api';

export interface CartLine {
  productId: string;
  name: string;
  priceCents: number;
  quantity: number;
}

interface Cart {
  lines: CartLine[];
  totalCents: number;
  itemCount: number;
  add(product: Product): void;
  setQuantity(productId: string, quantity: number): void;
  clear(): void;
}

const STORAGE_KEY = 'cart';
const CartContext = createContext<Cart | null>(null);

function loadLines(): CartLine[] {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY) ?? '[]');
  } catch {
    return [];
  }
}

/** Keeps the cart in the browser, so it survives a reload. */
export function CartProvider({ children }: { children: ReactNode }) {
  const [lines, setLines] = useState<CartLine[]>(loadLines);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(lines));
  }, [lines]);

  const cart = useMemo<Cart>(
    () => ({
      lines,
      totalCents: lines.reduce((sum, line) => sum + line.priceCents * line.quantity, 0),
      itemCount: lines.reduce((sum, line) => sum + line.quantity, 0),
      add(product) {
        setLines(current => {
          const existing = current.find(line => line.productId === product.id);
          if (existing) {
            return current.map(line => (line === existing ? { ...line, quantity: line.quantity + 1 } : line));
          }
          return [...current, { productId: product.id, name: product.name, priceCents: product.priceCents, quantity: 1 }];
        });
      },
      setQuantity(productId, quantity) {
        setLines(current =>
          quantity <= 0
            ? current.filter(line => line.productId !== productId)
            : current.map(line => (line.productId === productId ? { ...line, quantity } : line)),
        );
      },
      clear() {
        setLines([]);
      },
    }),
    [lines],
  );

  return <CartContext.Provider value={cart}>{children}</CartContext.Provider>;
}

export function useCart(): Cart {
  const cart = useContext(CartContext);
  if (!cart) throw new Error('useCart needs a CartProvider above it');
  return cart;
}
