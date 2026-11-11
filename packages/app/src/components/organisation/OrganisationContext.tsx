import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import type { ReactNode } from 'react';
import { fetchApiRef, useApi } from '@backstage/core-plugin-api';
import { organisationSlug, setBrandIdentity } from '@internal/brand';

/**
 * The signed-in user's organisation: its name, address and look, the
 * invitations waiting for them, and the calls that change these. A change
 * made at the organisation's own address re-themes the page at once.
 *
 * Usage:
 *   const { organisation, role, create, update, uploadLogo } = useOrganisation();
 */

export type Role = 'owner' | 'member';
export type LogoKind = 'full' | 'icon';

export interface Organisation {
  slug: string;
  name: string;
  logoFullUrl: string | null;
  logoIconUrl: string | null;
  primaryColor: string | null;
  themePreset: string | null;
}

/** An organisation that has asked the user to join. */
export interface ReceivedInvitation {
  slug: string;
  name: string;
  role: Role;
  invitedBy: string;
}

export interface Membership {
  organisation: Organisation | null;
  role: Role | null;
  userEntityRef: string;
  /** False for guests and for people who already have an organisation. */
  canCreate: boolean;
  invitations: ReceivedInvitation[];
}

export type OrganisationChanges = Partial<
  Pick<Organisation, 'name' | 'primaryColor' | 'themePreset'>
>;

interface OrganisationContextType extends Membership {
  isLoading: boolean;
  error: string | null;
  create: (name: string, slug: string) => Promise<Organisation>;
  /** Takes up an invitation. */
  join: (slug: string) => Promise<void>;
  /** Turns an invitation down. */
  decline: (slug: string) => Promise<void>;
  update: (changes: OrganisationChanges) => Promise<void>;
  /**
   * Changes the name or the address (`slug`), and answers with the
   * organisation as it then is. A refusal is thrown and not put in `error`:
   * it is about one field, and shown beside it.
   */
  rename: (
    change: { name: string } | { slug: string },
  ) => Promise<Organisation>;
  uploadLogo: (kind: LogoKind, file: File) => Promise<void>;
  removeLogo: (kind: LogoKind) => Promise<void>;
  remove: () => Promise<void>;
}

export const ORGANISATIONS_API = 'plugin://organisations';

const NOBODY: Membership = {
  organisation: null,
  role: null,
  userEntityRef: '',
  canCreate: false,
  invitations: [],
};

/** user:default/jane reads as jane. */
export const shortName = (userEntityRef: string) =>
  userEntityRef.replace(/^user:default\//, '');

/** The answer of a call, or an error with the message the backend gave. */
export async function answer<T>(
  response: Response,
  fallback: string,
): Promise<T> {
  if (response.ok) {
    return response.status === 204 ? (undefined as T) : response.json();
  }
  // A refusal is `{ error: "text" }`; anything the framework answers
  // itself, such as an expired sign-in, is `{ error: { message } }`.
  const data: unknown = await response.json().catch(() => undefined);
  let error: unknown =
    typeof data === 'object' && data && 'error' in data ? data.error : null;
  if (typeof error === 'object' && error && 'message' in error) {
    error = error.message;
  }
  throw new Error(typeof error === 'string' && error ? error : fallback);
}

const OrganisationContext = createContext<OrganisationContextType | undefined>(
  undefined,
);

export const OrganisationProvider = ({ children }: { children: ReactNode }) => {
  const fetchApi = useApi(fetchApiRef);
  const [membership, setMembership] = useState<Membership>(NOBODY);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  /** Keeps what the backend returned, and themes the page with it. */
  const show = useCallback((organisation: Organisation) => {
    if (organisation.slug === organisationSlug()) {
      setBrandIdentity(organisation);
    }
    setMembership(current => ({ ...current, organisation }));
  }, []);

  /** Runs a call, showing its failure in `error` as well as throwing it. */
  const attempt = useCallback(async <T,>(call: () => Promise<T>) => {
    setError(null);
    try {
      return await call();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : String(caught));
      throw caught;
    }
  }, []);

  const load = useCallback(
    async () =>
      setMembership(
        await answer<Membership>(
          await fetchApi.fetch(ORGANISATIONS_API),
          'Failed to load your organisation',
        ),
      ),
    [fetchApi],
  );

  useEffect(() => {
    attempt(load)
      .catch(() => {
        // Shown through `error`.
      })
      .finally(() => setIsLoading(false));
  }, [attempt, load]);

  const slug = membership.organisation?.slug;

  const value = useMemo<OrganisationContextType>(() => {
    /** A call that answers with the organisation as it then is. */
    const change = (path: string, init: RequestInit, fallback: string) =>
      attempt(async () =>
        show(
          await answer<Organisation>(
            await fetchApi.fetch(`${ORGANISATIONS_API}/${slug}${path}`, init),
            fallback,
          ),
        ),
      );
    const sendJson = (method: string, body: unknown): RequestInit => ({
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    return {
      ...membership,
      isLoading,
      error,
      create: (name, address) =>
        attempt(async () =>
          answer<Organisation>(
            await fetchApi.fetch(
              ORGANISATIONS_API,
              sendJson('POST', { name, slug: address }),
            ),
            'Failed to create the organisation',
          ),
        ),
      join: invited =>
        attempt(async () =>
          answer<void>(
            await fetchApi.fetch(`${ORGANISATIONS_API}/${invited}/join`, {
              method: 'POST',
            }),
            'Failed to join the organisation',
          ),
        ),
      decline: invited =>
        attempt(async () => {
          await answer<void>(
            await fetchApi.fetch(
              `${ORGANISATIONS_API}/${invited}/members/${encodeURIComponent(
                membership.userEntityRef,
              )}`,
              { method: 'DELETE' },
            ),
            'Failed to decline the invitation',
          );
          await load();
        }),
      update: changes =>
        change('', sendJson('PATCH', changes), 'Failed to save'),
      rename: async renamed => {
        setError(null);
        const organisation = await answer<Organisation>(
          await fetchApi.fetch(
            `${ORGANISATIONS_API}/${slug}`,
            sendJson('PATCH', renamed),
          ),
          'Failed to save',
        );
        show(organisation);
        return organisation;
      },
      uploadLogo: (kind, file) =>
        change(
          `/logo/${kind}`,
          { method: 'PUT', headers: { 'Content-Type': file.type }, body: file },
          'Failed to upload the logo',
        ),
      removeLogo: kind =>
        change(
          `/logo/${kind}`,
          { method: 'DELETE' },
          'Failed to remove the logo',
        ),
      remove: () =>
        attempt(async () =>
          answer<void>(
            await fetchApi.fetch(`${ORGANISATIONS_API}/${slug}`, {
              method: 'DELETE',
            }),
            'Failed to delete the organisation',
          ),
        ),
    };
  }, [attempt, error, fetchApi, isLoading, load, membership, show, slug]);

  return (
    <OrganisationContext.Provider value={value}>
      {children}
    </OrganisationContext.Provider>
  );
};

export const useOrganisation = (): OrganisationContextType => {
  const context = useContext(OrganisationContext);
  if (context === undefined) {
    throw new Error(
      'useOrganisation must be used within an OrganisationProvider',
    );
  }
  return context;
};
