import { useEffect } from 'react';
import { fetchApiRef, useApi } from '@backstage/core-plugin-api';

/**
 * A portal without administrators gives the role to the first signed-in
 * user who asks, and this is where the app asks: once, after sign-in.
 */
export const FirstAdminClaim = () => {
  const fetchApi = useApi(fetchApiRef);
  useEffect(() => {
    fetchApi.fetch('plugin://branding-settings/admin-check').catch(() => {
      // Asked again at the next sign-in.
    });
  }, [fetchApi]);
  return null;
};
