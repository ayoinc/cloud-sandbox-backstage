import type { Theme } from '@material-ui/core/styles';
import { brandOverrides, getBrandIdentity } from '../identity/brandIdentity';
import { brandTokensFor } from '../tokens/brandTokens';
import type { BrandMode } from '../tokens/brandTokens';
import { resolveBrandColors } from '../tokens/overrides';

/**
 * The tokens and colours in effect. Read where styles are computed from the
 * theme: the theme is rebuilt whenever the identity changes, so the two agree.
 */
export function activeBrand(theme: Theme) {
  const mode: BrandMode = theme.palette.type === 'dark' ? 'dark' : 'light';
  const identity = getBrandIdentity();
  return {
    mode,
    tokens: brandTokensFor(identity.themePreset),
    c: resolveBrandColors(mode, brandOverrides(identity)),
  };
}
