import React from 'react';
import { useIdleTimeout } from '../hooks/useIdleTimeout';

/**
 * Component that monitors user activity and signs them out after 1 hour of inactivity.
 * Add this component to your App.tsx to enable session idle timeout.
 */
export const IdleTimeoutMonitor: React.FC = () => {
  useIdleTimeout();
  return null; // This component doesn't render anything
};
