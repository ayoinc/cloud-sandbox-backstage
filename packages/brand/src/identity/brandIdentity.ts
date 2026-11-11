import { useEffect, useState } from 'react';
import type { BrandColorOverrides } from '../tokens/overrides';

/** An organisation in front of a path: `/o/acme` in `/o/acme/catalog`. */
const IN_ORGANISATION = /^\/o\/([a-z0-9][a-z0-9-]*)(?=\/|$)/;

/**
 * The organisation whose address this page is under: `acme` at
 * `/o/acme/catalog`, `null` anywhere else. An organisation's name, logo and
 * colours show at its own address only.
 */
export function organisationSlug(
  pathname: string = window.location.pathname,
): string | null {
  return IN_ORGANISATION.exec(pathname)?.[1] ?? null;
}

/**
 * The address of a page in an organisation, or outside any for `null`.
 * `page` is a path on this portal, with or without organisations in front.
 * The result is always a path on this portal too: whatever would make a
 * browser read it as another site's address is dropped.
 */
export function organisationPath(slug: string | null, page = '/'): string {
  // Browsers ignore tabs and line breaks in an address.
  let rest = page.replace(/[\t\n\r]/g, '');
  while (IN_ORGANISATION.test(rest)) {
    rest = rest.replace(IN_ORGANISATION, '');
  }
  rest = rest.replace(/^[/\\]+/, '').replace(/\/$/, '');
  const base = slug ? `/o/${slug}` : '';
  return rest ? `${base}/${rest}` : base || '/';
}

/**
 * What an organisation's owner has chosen for it. Every field is `null`
 * until it is set, and outside an organisation's address: the portal has no
 * name, logo or colours of its own.
 */
export interface BrandIdentity {
  name: string | null;
  logoFullUrl: string | null;
  logoIconUrl: string | null;
  primaryColor: string | null;
  themePreset: string | null;
}

const NONE: BrandIdentity = {
  name: null,
  logoFullUrl: null,
  logoIconUrl: null,
  primaryColor: null,
  themePreset: null,
};

const FIELDS = [
  'name',
  'logoFullUrl',
  'logoIconUrl',
  'primaryColor',
  'themePreset',
] as const;

/** How long the app waits for an organisation before starting without it. */
const LOAD_TIMEOUT_MS = 4000;

let current = NONE;
// Where logos are served from, when that is not where the page is: in
// development the backend has an address of its own.
let logoOrigin = '';
const listeners = new Set<() => void>();

/**
 * A logo's address as this page can load it. The organisations API names a
 * logo by its path on the backend; anything else is not a logo of ours.
 */
export const logoSrc = (url: string | null): string | null =>
  url && /^\/(?!\/)/.test(url) ? logoOrigin + url : null;

/** The identity in effect now. For code that cannot use the hook. */
export function getBrandIdentity(): BrandIdentity {
  return current;
}

/**
 * Replaces the identity and re-themes everything that reads it. Takes an
 * organisation as the organisations API returns it, or nothing for none.
 */
export function setBrandIdentity(organisation?: Partial<BrandIdentity>): void {
  const next = { ...NONE };
  for (const field of FIELDS) {
    const value: unknown = organisation?.[field];
    next[field] = typeof value === 'string' && value ? value : null;
  }
  next.logoFullUrl = logoSrc(next.logoFullUrl);
  next.logoIconUrl = logoSrc(next.logoIconUrl);
  if (FIELDS.every(field => next[field] === current[field])) {
    return;
  }
  current = next;
  listeners.forEach(listener => listener());
}

/**
 * The identity in effect, re-rendering when an owner changes it.
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
 * Loads the identity of the organisation this page is under, if any, and
 * returns the identity then in effect. Runs before the app starts, so the
 * first thing drawn is already right: an organisation's name and look are
 * public, and the request carries no token because there is none yet.
 * `backendUrl` is the backend's base address.
 *
 * An address nobody has, or a backend that does not answer in time, gives
 * no identity: the app starts plain rather than not at all.
 */
export async function loadBrandIdentity(
  backendUrl: string,
): Promise<BrandIdentity> {
  const { origin } = new URL(backendUrl);
  logoOrigin = origin === window.location.origin ? '' : origin;
  const slug = organisationSlug();
  if (!slug) {
    return current;
  }
  const waiting = new AbortController();
  const timer = setTimeout(() => waiting.abort(), LOAD_TIMEOUT_MS);
  try {
    const response = await fetch(`${backendUrl}/api/organisations/${slug}`, {
      signal: waiting.signal,
    });
    setBrandIdentity(response.ok ? await response.json() : undefined);
  } catch {
    setBrandIdentity();
  } finally {
    clearTimeout(timer);
  }
  return current;
}
