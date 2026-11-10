import type { CSSProperties, SVGProps } from 'react';
import { brandTokens } from '../tokens/brandTokens';
import {
  LOGO_VIEWBOX,
  MARK_PATH,
  MARK_VIEWBOX,
  REPLY_PATH,
  SOLIRIUS_PATH,
} from './logoPaths';

const [, , LOGO_WIDTH, LOGO_HEIGHT] = LOGO_VIEWBOX.split(' ').map(Number);
/** Width-to-height ratio of the full lockup artwork. */
const LOGO_ASPECT = LOGO_WIDTH / LOGO_HEIGHT;

/**
 * Logo colour treatment.
 * - `color`: official two-colour artwork, for light surfaces.
 * - `reversed`: single-colour white, for dark surfaces such as the sidebar.
 */
export type LogoTone = 'color' | 'reversed';

/** Props shared by {@link LogoFull} and {@link LogoIcon}. */
export interface LogoProps
  extends Omit<SVGProps<SVGSVGElement>, 'ref' | 'children' | 'viewBox'> {
  /** Colour treatment. Defaults to `reversed`, matching the dark sidebar. */
  tone?: LogoTone;
  /**
   * Accessible name. Defaults to "Solirius Reply". Pass an empty string when
   * the logo is decorative (for example inside a link that is already named).
   */
  title?: string;
  /**
   * Administrator-supplied image URL. When set, it replaces the built-in
   * artwork (branding settings override the brand default).
   */
  src?: string | null;
  /** Rendered height in px. Width follows the artwork's aspect ratio. */
  height?: number;
}

function toneColors(tone: LogoTone) {
  const { identity } = brandTokens;
  return tone === 'color'
    ? {
        figure: identity.soliriusBlue,
        reply: identity.replyTeal,
        solirius: identity.soliriusBlue,
      }
    : {
        figure: identity.white,
        reply: identity.white,
        solirius: identity.white,
      };
}

function OverrideImage(props: {
  src: string;
  title: string;
  height: number;
  className?: string;
  style?: CSSProperties;
}) {
  return (
    <img
      src={props.src}
      alt={props.title}
      className={props.className}
      style={{
        height: props.height,
        width: 'auto',
        display: 'block',
        ...props.style,
      }}
    />
  );
}

/** Full Solirius Reply lockup: running figure, REPLY and SOLIRIUS. */
export function LogoFull(props: LogoProps) {
  const {
    tone = 'reversed',
    title = brandTokens.name.company,
    src,
    height = 36,
    style,
    className,
    ...rest
  } = props;
  if (src) {
    return (
      <OverrideImage
        src={src}
        title={title}
        height={height}
        className={className}
        style={style}
      />
    );
  }
  const colors = toneColors(tone);
  const decorative = title === '';
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox={LOGO_VIEWBOX}
      role={decorative ? undefined : 'img'}
      aria-hidden={decorative ? true : undefined}
      focusable="false"
      className={className}
      style={{
        height,
        width: height * LOGO_ASPECT,
        display: 'block',
        ...style,
      }}
      {...rest}
    >
      {decorative ? null : <title>{title}</title>}
      <path fillRule="evenodd" fill={colors.figure} d={MARK_PATH} />
      <path fillRule="evenodd" fill={colors.reply} d={REPLY_PATH} />
      <path fillRule="evenodd" fill={colors.solirius} d={SOLIRIUS_PATH} />
    </svg>
  );
}

/** Running figure mark on its own, for the collapsed sidebar and small spaces. */
export function LogoIcon(props: LogoProps) {
  const {
    tone = 'reversed',
    title = brandTokens.name.company,
    src,
    height = 32,
    style,
    className,
    ...rest
  } = props;
  if (src) {
    return (
      <OverrideImage
        src={src}
        title={title}
        height={height}
        className={className}
        style={style}
      />
    );
  }
  const colors = toneColors(tone);
  const decorative = title === '';
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox={MARK_VIEWBOX}
      role={decorative ? undefined : 'img'}
      aria-hidden={decorative ? true : undefined}
      focusable="false"
      className={className}
      style={{ height, width: height, display: 'block', ...style }}
      {...rest}
    >
      {decorative ? null : <title>{title}</title>}
      <path fillRule="evenodd" fill={colors.figure} d={MARK_PATH} />
    </svg>
  );
}
