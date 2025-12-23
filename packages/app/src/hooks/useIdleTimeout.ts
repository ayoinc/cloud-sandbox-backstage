import { useEffect, useCallback, useRef } from 'react';
import { useApi, identityApiRef, errorApiRef } from '@backstage/core-plugin-api';

const IDLE_TIMEOUT_MS = 60 * 60 * 1000; // 1 hour in milliseconds
const ACTIVITY_EVENTS = [
  'mousedown',
  'mousemove',
  'keydown',
  'scroll',
  'touchstart',
  'click',
];

/**
 * Hook that monitors user activity and signs them out after 1 hour of inactivity.
 * Tracks mouse movements, keyboard input, scrolling, and touch events.
 */
export function useIdleTimeout() {
  const identityApi = useApi(identityApiRef);
  const errorApi = useApi(errorApiRef);
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);
  const isSigningOutRef = useRef(false);

  const signOut = useCallback(async () => {
    if (isSigningOutRef.current) return;
    isSigningOutRef.current = true;

    try {
      await identityApi.signOut();
      // Redirect to sign-in page
      window.location.href = '/';
    } catch (error) {
      errorApi.post(new Error('Failed to sign out due to inactivity'));
      isSigningOutRef.current = false;
    }
  }, [identityApi, errorApi]);

  const resetTimer = useCallback(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    timeoutRef.current = setTimeout(() => {
      signOut();
    }, IDLE_TIMEOUT_MS);
  }, [signOut]);

  useEffect(() => {
    // Check if user is signed in before setting up idle timeout
    const checkIdentityAndSetup = async () => {
      try {
        const identity = await identityApi.getBackstageIdentity();
        if (!identity) {
          // User not signed in, don't set up idle timeout
          return;
        }

        // Set up activity listeners
        ACTIVITY_EVENTS.forEach(event => {
          document.addEventListener(event, resetTimer, { passive: true });
        });

        // Start the initial timer
        resetTimer();
      } catch {
        // User not signed in, don't set up idle timeout
      }
    };

    checkIdentityAndSetup();

    // Cleanup
    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
      ACTIVITY_EVENTS.forEach(event => {
        document.removeEventListener(event, resetTimer);
      });
    };
  }, [identityApi, resetTimer]);
}
