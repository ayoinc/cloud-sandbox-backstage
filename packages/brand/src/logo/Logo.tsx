import type { CSSProperties } from 'react';
import { useBrandIdentity } from '../identity/brandIdentity';

/** Props shared by {@link LogoFull} and {@link LogoIcon}. */
export interface LogoProps {
  /**
   * Accessible name. Defaults to the organisation's name. Pass an empty
   * string when the logo is decorative (for example inside a named link).
   */
  title?: string;
  /** Rendered height in px. Width follows the artwork. */
  height?: number;
  className?: string;
  style?: CSSProperties;
}

const FALLBACK_NAME = 'Developer portal';

function Uploaded(props: LogoProps & { src: string; alt: string }) {
  return (
    <img
      src={props.src}
      alt={props.alt}
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

/**
 * The mark shown until an organisation uploads its own: a plain glyph in
 * the surrounding text colour, belonging to nobody.
 */
function PlainMark(props: LogoProps & { label: string }) {
  const { height, label, className, style } = props;
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      role={label ? 'img' : undefined}
      aria-label={label || undefined}
      aria-hidden={label ? undefined : true}
      focusable="false"
      className={className}
      style={{
        height,
        width: height,
        display: 'block',
        flex: 'none',
        ...style,
      }}
    >
      <rect width="24" height="24" rx="6" fill="currentColor" opacity="0.18" />
      <path
        d="M7 8h10M7 12h10M7 16h6"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
      />
    </svg>
  );
}

/**
 * The organisation's full logo. Without an uploaded one: the plain mark,
 * followed by the organisation's name when it has been set.
 */
export function LogoFull(props: LogoProps) {
  const { name, logoFullUrl } = useBrandIdentity();
  const { height = 36, className, style } = props;
  const label = props.title ?? name ?? FALLBACK_NAME;
  if (logoFullUrl) {
    return (
      <Uploaded {...props} height={height} src={logoFullUrl} alt={label} />
    );
  }
  return (
    <span
      role={label ? 'img' : undefined}
      aria-label={label || undefined}
      className={className}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: height / 3,
        height,
        maxWidth: '100%',
        ...style,
      }}
    >
      <PlainMark title="" label="" height={height} />
      {name ? (
        <span
          aria-hidden="true"
          style={{
            fontSize: height / 2,
            fontWeight: 700,
            lineHeight: 1.1,
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
          }}
        >
          {name}
        </span>
      ) : null}
    </span>
  );
}

/** The organisation's icon, for the collapsed sidebar and small spaces. */
export function LogoIcon(props: LogoProps) {
  const { name, logoIconUrl } = useBrandIdentity();
  const { height = 32 } = props;
  const label = props.title ?? name ?? FALLBACK_NAME;
  if (logoIconUrl) {
    return (
      <Uploaded {...props} height={height} src={logoIconUrl} alt={label} />
    );
  }
  return <PlainMark {...props} height={height} label={label} />;
}
