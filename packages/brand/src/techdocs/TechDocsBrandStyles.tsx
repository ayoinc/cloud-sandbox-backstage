import { useEffect } from 'react';
import { useTheme } from '@material-ui/core/styles';
import { useShadowRoot } from '@backstage/plugin-techdocs-react';
import { AddonBlueprint } from '@backstage/plugin-techdocs-react/alpha';
import { techdocsBrandCss } from './techdocsBrandCss';

/**
 * TechDocs `Content` addon that injects the brand stylesheet into the
 * documentation shadow root. Renders nothing.
 */
export function TechDocsBrandStyles() {
  const shadowRoot = useShadowRoot();
  const mode = useTheme().palette.type === 'dark' ? 'dark' : 'light';
  useEffect(() => {
    if (!shadowRoot) {
      return undefined;
    }
    const style = document.createElement('style');
    style.setAttribute('data-brand-techdocs', `solirius-${mode}`);
    style.textContent = techdocsBrandCss(mode);
    shadowRoot.appendChild(style);
    return () => style.remove();
  }, [shadowRoot, mode]);
  return null;
}

/** TechDocs addon extension for the new frontend system. */
export const techDocsBrandAddon = AddonBlueprint.make({
  name: 'solirius-brand-styles',
  params: {
    name: 'SoliriusBrandStyles',
    location: 'Content',
    component: TechDocsBrandStyles,
  },
});
