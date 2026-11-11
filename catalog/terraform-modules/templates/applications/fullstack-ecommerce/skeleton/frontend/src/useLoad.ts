import { useCallback, useEffect, useState } from 'react';

export interface Loaded<T> {
  data?: T;
  error?: string;
  /** Loads again, for example after a change. */
  reload(): void;
}

/**
 * Loads data when the component appears and whenever `load` changes, so
 * `load` should come from useCallback or be a stable function.
 */
export function useLoad<T>(load: () => Promise<T>): Loaded<T> {
  const [state, setState] = useState<{ data?: T; error?: string }>({});
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let current = true;
    load().then(
      data => current && setState({ data }),
      (error: Error) => current && setState({ error: error.message }),
    );
    return () => {
      current = false;
    };
  }, [load, attempt]);

  const reload = useCallback(() => setAttempt(value => value + 1), []);
  return { ...state, reload };
}
