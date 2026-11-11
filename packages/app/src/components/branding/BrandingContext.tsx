import {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
} from 'react';
import type { ReactNode } from 'react';
import {
  useApi,
  discoveryApiRef,
  fetchApiRef,
  identityApiRef,
} from '@backstage/core-plugin-api';
import { getBrandIdentity, setBrandIdentity } from '@internal/brand';

/**
 * =============================================================================
 * Branding Context
 * =============================================================================
 *
 * Loads the branding settings (name, logo, theme preset, primary colour) and
 * lets an administrator change them. Whatever it loads or saves goes to the
 * brand identity store, which is what every themed surface reads.
 *
 * Usage:
 *   const { settings, isAdmin, updateSettings, uploadLogo } = useBranding();
 *
 * =============================================================================
 */

export interface BrandingSettings {
  organizationName: string | null;
  logoFullUrl: string | null;
  logoIconUrl: string | null;
  primaryColor: string | null;
  themePreset: string | null;
  updatedAt: string | null;
  updatedBy: string | null;
}

interface BrandingContextType {
  settings: BrandingSettings;
  isLoading: boolean;
  isAdmin: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  updateSettings: (updates: Partial<BrandingSettings>) => Promise<void>;
  uploadLogo: (logoFull?: File, logoIcon?: File) => Promise<void>;
  resetLogo: () => Promise<void>;
  resetAll: () => Promise<void>;
}

const DEFAULT_SETTINGS: BrandingSettings = {
  organizationName: null,
  logoFullUrl: null,
  logoIconUrl: null,
  primaryColor: null,
  themePreset: null,
  updatedAt: null,
  updatedBy: null,
};

/** The message of a failed response, in either backend's error format. */
const failure = (data: unknown, fallback: string) => {
  const error = (data as { error?: string | { message?: string } })?.error;
  return (typeof error === 'string' ? error : error?.message) || fallback;
};

const BrandingContext = createContext<BrandingContextType | undefined>(
  undefined,
);

interface BrandingProviderProps {
  children: ReactNode;
}

export const BrandingProvider: React.FC<BrandingProviderProps> = ({
  children,
}) => {
  const fetchApi = useApi(fetchApiRef);
  const identityApi = useApi(identityApiRef);

  const [settings, setLoaded] = useState<BrandingSettings>(DEFAULT_SETTINGS);
  const discoveryApi = useApi(discoveryApiRef);
  const setSettings = useCallback(
    async (loaded: BrandingSettings) => {
      setBrandIdentity(
        loaded,
        await discoveryApi.getBaseUrl('branding-settings'),
      );
      // The logo addresses as this page can load them.
      const { logoFullUrl, logoIconUrl } = getBrandIdentity();
      setLoaded({ ...loaded, logoFullUrl, logoIconUrl });
    },
    [discoveryApi],
  );
  const [isLoading, setIsLoading] = useState(true);
  const [isAdmin, setIsAdmin] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // plugin:// is resolved by fetchApi through the discovery API
  const baseUrl = 'plugin://branding-settings';

  // Fetch current branding settings
  const refresh = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);

      const response = await fetchApi.fetch(baseUrl);
      if (response.ok) {
        const data = await response.json();
        await setSettings(data);
      } else {
        console.warn('Failed to fetch branding settings:', response.status);
      }
    } catch (err) {
      console.error('Error fetching branding settings:', err);
      setError('Failed to load branding settings');
    } finally {
      setIsLoading(false);
    }
  }, [fetchApi, setSettings]);

  // Check if current user is admin
  const checkAdmin = useCallback(async () => {
    try {
      const identity = await identityApi.getBackstageIdentity();
      if (!identity?.userEntityRef) {
        setIsAdmin(false);
        return;
      }

      const response = await fetchApi.fetch(`${baseUrl}/admin-check`);
      if (response.ok) {
        const data = await response.json();
        setIsAdmin(data.isAdmin);
      }
    } catch (err) {
      console.error('Error checking admin status:', err);
      setIsAdmin(false);
    }
  }, [fetchApi, identityApi]);

  // Update branding settings (text fields)
  const updateSettings = useCallback(
    async (updates: Partial<BrandingSettings>) => {
      try {
        setError(null);
        const response = await fetchApi.fetch(baseUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(updates),
        });

        if (!response.ok) {
          const data = await response.json();
          throw new Error(failure(data, 'Failed to update settings'));
        }

        const data = await response.json();
        await setSettings(data);
      } catch (err) {
        const message =
          err instanceof Error ? err.message : 'Failed to update settings';
        setError(message);
        throw err;
      }
    },
    [fetchApi, setSettings],
  );

  // Upload logo files
  const uploadLogo = useCallback(
    async (logoFull?: File, logoIcon?: File) => {
      try {
        setError(null);
        const formData = new FormData();

        if (logoFull) {
          formData.append('logoFull', logoFull);
        }
        if (logoIcon) {
          formData.append('logoIcon', logoIcon);
        }

        const response = await fetchApi.fetch(`${baseUrl}/logo/upload`, {
          method: 'POST',
          body: formData,
        });

        if (!response.ok) {
          const data = await response.json();
          throw new Error(failure(data, 'Failed to upload logo'));
        }

        const data = await response.json();
        await setSettings(data);
      } catch (err) {
        const message =
          err instanceof Error ? err.message : 'Failed to upload logo';
        setError(message);
        throw err;
      }
    },
    [fetchApi, setSettings],
  );

  // Reset logo to default
  const resetLogo = useCallback(async () => {
    try {
      setError(null);
      const response = await fetchApi.fetch(`${baseUrl}/logo`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(failure(data, 'Failed to reset logo'));
      }

      const data = await response.json();
      await setSettings(data);
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Failed to reset logo';
      setError(message);
      throw err;
    }
  }, [fetchApi, setSettings]);

  // Reset all branding to default
  const resetAll = useCallback(async () => {
    try {
      setError(null);
      const response = await fetchApi.fetch(baseUrl, {
        method: 'DELETE',
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(failure(data, 'Failed to reset branding'));
      }

      const data = await response.json();
      await setSettings(data);
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Failed to reset branding';
      setError(message);
      throw err;
    }
  }, [fetchApi, setSettings]);

  // Initial fetch
  useEffect(() => {
    refresh();
    checkAdmin();
  }, [refresh, checkAdmin]);

  const value: BrandingContextType = {
    settings,
    isLoading,
    isAdmin,
    error,
    refresh,
    updateSettings,
    uploadLogo,
    resetLogo,
    resetAll,
  };

  return (
    <BrandingContext.Provider value={value}>
      {children}
    </BrandingContext.Provider>
  );
};

export const useBranding = (): BrandingContextType => {
  const context = useContext(BrandingContext);
  if (context === undefined) {
    throw new Error('useBranding must be used within a BrandingProvider');
  }
  return context;
};

export default BrandingContext;
