import { useState, useEffect } from 'react';
import { useApi, fetchApiRef } from '@backstage/core-plugin-api';

/**
 * =============================================================================
 * Branding Settings Hook
 * =============================================================================
 * 
 * A simple hook to fetch branding settings without requiring a provider.
 * Suitable for components that render before the full app context is available.
 * 
 * =============================================================================
 */

export interface BrandingSettings {
  organizationName: string | null;
  logoFullUrl: string | null;
  logoIconUrl: string | null;
  primaryColor: string | null;
  updatedAt: string;
  updatedBy: string | null;
}

const DEFAULT_SETTINGS: BrandingSettings = {
  organizationName: null,
  logoFullUrl: null,
  logoIconUrl: null,
  primaryColor: null,
  updatedAt: new Date().toISOString(),
  updatedBy: null,
};

// Cache for branding settings to avoid multiple fetches
let cachedSettings: BrandingSettings | null = null;
let fetchPromise: Promise<BrandingSettings> | null = null;

export function useBrandingSettings(): {
  settings: BrandingSettings;
  isLoading: boolean;
} {
  const fetchApi = useApi(fetchApiRef);
  const [settings, setSettings] = useState<BrandingSettings>(cachedSettings || DEFAULT_SETTINGS);
  const [isLoading, setIsLoading] = useState(!cachedSettings);

  useEffect(() => {
    // If already cached, use it
    if (cachedSettings) {
      setSettings(cachedSettings);
      setIsLoading(false);
      return;
    }

    // If fetch is in progress, wait for it
    if (fetchPromise) {
      fetchPromise.then((data) => {
        setSettings(data);
        setIsLoading(false);
      });
      return;
    }

    // Start fetching
    fetchPromise = fetchApi
      .fetch('/api/branding-settings')
      .then(async (response) => {
        if (response.ok) {
          const data = await response.json();
          cachedSettings = data;
          return data;
        }
        return DEFAULT_SETTINGS;
      })
      .catch(() => DEFAULT_SETTINGS)
      .finally(() => {
        fetchPromise = null;
      });

    fetchPromise.then((data) => {
      setSettings(data);
      setIsLoading(false);
    });
  }, [fetchApi]);

  return { settings, isLoading };
}

/**
 * Clear the cached settings (call after updating settings)
 */
export function clearBrandingCache(): void {
  cachedSettings = null;
  fetchPromise = null;
}

export default useBrandingSettings;
