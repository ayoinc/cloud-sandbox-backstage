import { createContext, useContext } from 'react';
import type { Features } from './api';

/** Which optional parts of the store are on, as reported by the API. */
export const FeaturesContext = createContext<Features | null>(null);

export function useFeatures(): Features {
  const features = useContext(FeaturesContext);
  if (!features) throw new Error('useFeatures needs a FeaturesContext provider above it');
  return features;
}
