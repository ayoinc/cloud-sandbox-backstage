import { useIdleTimeout } from './useIdleTimeout';

/**
 * Monitors user activity and signs the user out after 1 hour of inactivity.
 */
export const IdleTimeoutMonitor = () => {
  useIdleTimeout();
  return null;
};
