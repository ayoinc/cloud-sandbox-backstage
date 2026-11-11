import { useEffect, useState } from 'react';
import { discoveryApiRef, useApi } from '@backstage/core-plugin-api';
import type { BrandColorOverrides } from '../tokens/overrides';

/**
 * What an administrator has chosen for this portal. Every field is `null`
 * until it is set: the portal ships with no organisation's name, logo or
 * colours of its own.
 */
export interface BrandIdentity {
  organizationName: string | null;
  logoFullUrl: string | null;
  logoIconUrl: string | null;
  primaryColor: string | null;
  themePreset: string | null;
}

const FIELDS = [
  'organizationName',
  'logoFullUrl',
  'logoIconUrl',
  'primaryColor',
  'themePreset',
] as const;

// The last identity seen is kept in the browser, so a returning visitor's
// first paint is already in their organisation's theme.
const STORAGE_KEY = 'brand-identity';

function pick(source: unknown): BrandIdentity {
  const record = (
    typeof source === 'object' && source !== null ? source : {}
  ) as Record<string, unknown>;
  const text = (key: string) =>
    typeof record[key] === 'string' && record[key] ? record[key] : null;
  return {
    organizationName: text('organizationName'),
    logoFullUrl: text('logoFullUrl'),
    logoIconUrl: text('logoIconUrl'),
    primaryColor: text('primaryColor'),
    themePreset: text('themePreset'),
  };
}

function stored(): BrandIdentity {
  try {
    return pick(JSON.parse(window.localStorage.getItem(STORAGE_KEY) ?? '{}'));
  } catch {
    // No storage, or something else's value under the key: start unbranded.
    return pick(undefined);
  }
}

let current = stored();
const listeners = new Set<() => void>();

/** The identity in effect now. For code that cannot use the hook. */
export function getBrandIdentity(): BrandIdentity {
  return current;
}

/**
 * Replaces the identity with what the branding settings API returned, and
 * re-themes everything that reads it.
 */
export function setBrandIdentity(settings: unknown): void {
  const next = pick(settings);
  if (FIELDS.every(field => next[field] === current[field])) {
    return;
  }
  current = next;
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  } catch {
    // Storage is full or blocked; the identity still applies to this visit.
  }
  listeners.forEach(listener => listener());
}

/**
 * The identity in effect, re-rendering when an administrator changes it.
 *
 * A change arrives as an ordinary state update rather than through
 * `useSyncExternalStore`: that hook renders synchronously, and a lazy
 * component under a re-themed tree may suspend, which React refuses to do
 * during a synchronous render.
 */
export function useBrandIdentity(): BrandIdentity {
  const [identity, setIdentity] = useState(current);
  useEffect(() => {
    const listener = () => setIdentity(current);
    listeners.add(listener);
    // Catch a change made between the first render and this effect.
    listener();
    return () => {
      listeners.delete(listener);
    };
  }, []);
  return identity;
}

/** The theme part of an identity, in the form the theme builders take. */
export function brandOverrides(
  identity: Pick<BrandIdentity, 'themePreset' | 'primaryColor'>,
): BrandColorOverrides {
  return { preset: identity.themePreset, primaryColor: identity.primaryColor };
}

/**
 * Loads the identity from the branding settings API. For screens shown
 * before sign-in: the settings are public, and the request carries no token
 * because there is none yet.
 */
export function useLoadBrandIdentity(): void {
  const discoveryApi = useApi(discoveryApiRef);
  useEffect(() => {
    let live = true;
    discoveryApi
      .getBaseUrl('branding-settings')
      .then(url => fetch(url))
      .then(response => (response.ok ? response.json() : undefined))
      .then(settings => {
        if (live && settings) {
          setBrandIdentity(settings);
        }
      })
      // Unreachable settings leave the last known identity in place.
      .catch(() => undefined);
    return () => {
      live = false;
    };
  }, [discoveryApi]);
}
