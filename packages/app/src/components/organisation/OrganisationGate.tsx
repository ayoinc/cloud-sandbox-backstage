import { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { fetchApiRef, useApi } from '@backstage/core-plugin-api';
import { organisationPath, organisationSlug } from '@internal/brand';
import { ORGANISATIONS_API, answer } from './OrganisationContext';
import type { Membership } from './OrganisationContext';

/**
 * What this browser has already taken its user to the Organisation tab for:
 * the user, then `create` once the form that creates one has been shown,
 * and the slug of every invitation shown. The same invitation is not shown
 * twice, declined or not; one from another organisation is new.
 */
const SHOWN_KEY = 'organisation-shown';

function shownBefore(user: string): string[] {
  try {
    const stored: unknown = JSON.parse(
      window.localStorage.getItem(SHOWN_KEY) ?? 'null',
    );
    return Array.isArray(stored) && stored[0] === user
      ? stored.filter(item => typeof item === 'string')
      : [user];
  } catch {
    return [user];
  }
}

/**
 * Puts a signed-in user at the right address, once, when the app has
 * loaded. Someone in an organisation is moved to its address, whichever one
 * they signed in at; someone who is not is moved out of other people's.
 * Whoever arrives at the front page with an invitation they have not seen,
 * or with no organisation and the right to create one, is taken to the
 * Organisation tab.
 */
export const OrganisationGate = () => {
  const fetchApi = useApi(fetchApiRef);
  // The router hands out a new function on every page change; this effect
  // is for the load, not for each page.
  const navigate = useRef(useNavigate());

  useEffect(() => {
    let live = true;
    (async () => {
      const { organisation, canCreate, invitations, userEntityRef } =
        await answer<Membership>(
          await fetchApi.fetch(ORGANISATIONS_API),
          'Failed to load your organisation',
        );
      if (!live) {
        return;
      }
      const { pathname, search, hash } = window.location;
      const here = organisationSlug(pathname);
      const home = organisation?.slug ?? null;
      if (here !== home) {
        // A full load: the app has to start again under the other address.
        window.location.replace(
          organisationPath(home, pathname) + search + hash,
        );
        return;
      }
      // Only from the front page: a link to anywhere else is where the
      // user asked to go.
      if (organisationPath(null, pathname) !== '/') {
        return;
      }
      const shown = shownBefore(userEntityRef);
      const toShow = [
        ...(canCreate ? ['create'] : []),
        ...invitations.map(invitation => invitation.slug),
      ].filter(item => !shown.includes(item));
      if (toShow.length) {
        window.localStorage.setItem(
          SHOWN_KEY,
          JSON.stringify([...shown, ...toShow]),
        );
        navigate.current('/settings/organisation');
      }
    })().catch(() => {
      // The organisations API is unreachable: stay where we are.
    });
    return () => {
      live = false;
    };
  }, [fetchApi]);

  return null;
};
