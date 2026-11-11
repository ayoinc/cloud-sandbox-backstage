import { useEffect, useState } from 'react';
import { makeStyles } from '@material-ui/core/styles';
import { EASE } from '../stageshow/kit/ease';

/** One line of a run worth showing to the person waiting for it. */
export interface RunActivityLine {
  id: number | string;
  text: string;
  tone?: 'normal' | 'success' | 'warning' | 'error';
}

export interface RunActivityCardProps {
  /** Whether the run is still going, or how it ended. */
  state: 'running' | 'done' | 'failed';
  /** What the run is doing now, in a few words. */
  phase: string;
  /** When the run was started, in milliseconds since the epoch. */
  startedAt: number;
  /** When it ended; the clock stops there. */
  endedAt?: number;
  /** The important lines, oldest first. The last few are shown. */
  lines: RunActivityLine[];
  /** The run in GitHub Actions, once it is known. */
  runUrl?: string;
}

const VISIBLE_LINES = 5;
// The Stageshow curve for something arriving and settling into place.
const SETTLE = `cubic-bezier(${EASE.settle.join(', ')})`;

const useStyles = makeStyles(theme => ({
  '@keyframes runActivityIn': {
    from: { opacity: 0, transform: 'translateY(12px) scale(0.98)' },
    to: { opacity: 1, transform: 'none' },
  },
  '@keyframes runActivityLine': {
    from: { opacity: 0, transform: 'translateY(8px)' },
    to: { opacity: 1, transform: 'none' },
  },
  '@keyframes runActivitySpin': {
    to: { transform: 'rotate(360deg)' },
  },
  '@keyframes runActivitySweep': {
    from: { transform: 'translateX(-100%)' },
    to: { transform: 'translateX(350%)' },
  },
  '@keyframes runActivityTick': {
    from: { strokeDashoffset: 12 },
    to: { strokeDashoffset: 0 },
  },
  card: {
    position: 'fixed',
    right: theme.spacing(3),
    bottom: theme.spacing(3),
    zIndex: theme.zIndex.snackbar,
    width: 380,
    maxWidth: `calc(100vw - ${theme.spacing(4)}px)`,
    borderRadius: 12,
    overflow: 'hidden',
    color: theme.palette.text.primary,
    background: theme.palette.background.paper,
    border: `1px solid ${theme.palette.divider}`,
    boxShadow: theme.shadows[8],
    animation: `$runActivityIn 600ms ${SETTLE} both`,
    '@media (prefers-reduced-motion: reduce)': {
      animation: 'none',
      '& *': { animation: 'none !important', transition: 'none !important' },
    },
  },
  header: {
    display: 'flex',
    alignItems: 'center',
    gap: theme.spacing(1.5),
    width: '100%',
    padding: theme.spacing(1.5, 2),
    border: 0,
    background: 'none',
    color: 'inherit',
    font: 'inherit',
    textAlign: 'left',
    cursor: 'pointer',
    '&:focus-visible': {
      outline: `2px solid ${theme.palette.primary.main}`,
      outlineOffset: -2,
    },
  },
  mark: { flex: 'none', width: 20, height: 20 },
  spinner: {
    color: theme.palette.primary.main,
    animation: '$runActivitySpin 0.8s linear infinite',
  },
  tick: {
    strokeDasharray: 12,
    animation: `$runActivityTick 450ms ${SETTLE} both`,
  },
  phase: {
    flex: 1,
    minWidth: 0,
    fontWeight: 700,
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap',
  },
  clock: {
    flex: 'none',
    fontVariantNumeric: 'tabular-nums',
    color: theme.palette.text.secondary,
    fontSize: '0.875rem',
  },
  track: {
    height: 2,
    overflow: 'hidden',
    background: theme.palette.divider,
  },
  sweep: {
    width: '40%',
    height: '100%',
    background: theme.palette.primary.main,
    animation: '$runActivitySweep 1.6s ease-in-out infinite',
  },
  settled: { width: '100%', height: '100%', transition: 'background 300ms' },
  body: { padding: theme.spacing(1.5, 2, 2) },
  lines: { listStyle: 'none', margin: 0, padding: 0 },
  line: {
    display: 'flex',
    gap: theme.spacing(1),
    padding: theme.spacing(0.5, 0),
    fontSize: '0.875rem',
    lineHeight: 1.4,
    color: theme.palette.text.secondary,
    overflowWrap: 'anywhere',
    animation: `$runActivityLine 500ms ${SETTLE} both`,
    transition: 'color 300ms',
    '&:last-child': { color: theme.palette.text.primary },
  },
  dot: {
    flex: 'none',
    width: 6,
    height: 6,
    marginTop: 7,
    borderRadius: '50%',
    background: 'currentColor',
    opacity: 0.5,
  },
  success: { '& $dot': { background: theme.palette.success.main, opacity: 1 } },
  warning: { '& $dot': { background: theme.palette.warning.main, opacity: 1 } },
  error: {
    color: `${theme.palette.error.main} !important`,
    '& $dot': { opacity: 1 },
  },
  empty: { fontSize: '0.875rem', color: theme.palette.text.secondary },
  link: {
    display: 'inline-block',
    marginTop: theme.spacing(1.5),
    fontSize: '0.875rem',
    color: theme.palette.primary.main,
  },
}));

const clock = (ms: number) => {
  const total = Math.max(0, Math.floor(ms / 1000));
  return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, '0')}`;
};

/**
 * A live summary of a pipeline run, fixed to the corner of the page: a mark
 * that keeps turning until the run ends, what the run is doing now, how long
 * it has taken, and its last few important lines. Lines arrive one at a time
 * and settle into place. Under reduced motion nothing moves.
 */
export function RunActivityCard({
  state,
  phase,
  startedAt,
  endedAt,
  lines,
  runUrl,
}: RunActivityCardProps) {
  const classes = useStyles();
  const [open, setOpen] = useState(true);
  const [now, setNow] = useState(() => Date.now());
  const running = state === 'running';

  useEffect(() => {
    if (!running) {
      return undefined;
    }
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, [running]);

  const colour = state === 'failed' ? 'error' : 'success';
  return (
    <section className={classes.card} aria-label="Run activity">
      <button
        type="button"
        className={classes.header}
        aria-expanded={open}
        onClick={() => setOpen(value => !value)}
      >
        {running ? (
          <svg
            className={`${classes.mark} ${classes.spinner}`}
            viewBox="0 0 20 20"
            aria-hidden
          >
            <circle
              cx="10"
              cy="10"
              r="8"
              fill="none"
              stroke="currentColor"
              strokeOpacity="0.2"
              strokeWidth="2"
            />
            <path
              d="M10 2a8 8 0 0 1 8 8"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
          </svg>
        ) : (
          <svg className={classes.mark} viewBox="0 0 20 20" aria-hidden>
            <circle
              cx="10"
              cy="10"
              r="10"
              fill={state === 'failed' ? '#d4351c' : '#00703c'}
            />
            <path
              className={classes.tick}
              d={
                state === 'failed'
                  ? 'M7 7l6 6M13 7l-6 6'
                  : 'M6 10.5l2.8 2.8L14.5 7.5'
              }
              fill="none"
              stroke="#fff"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        )}
        <span className={classes.phase} role="status">
          {phase}
        </span>
        <span className={classes.clock}>
          {clock((endedAt ?? now) - startedAt)}
        </span>
      </button>
      <div className={classes.track} aria-hidden>
        {running ? (
          <div className={classes.sweep} />
        ) : (
          <div
            className={classes.settled}
            style={{ background: colour === 'error' ? '#d4351c' : '#00703c' }}
          />
        )}
      </div>
      {open && (
        <div className={classes.body}>
          {lines.length === 0 ? (
            <div className={classes.empty}>Waiting for the first update…</div>
          ) : (
            <ol className={classes.lines} aria-live="polite">
              {lines.slice(-VISIBLE_LINES).map(line => (
                <li
                  key={line.id}
                  className={`${classes.line} ${
                    line.tone && line.tone !== 'normal'
                      ? classes[line.tone]
                      : ''
                  }`}
                >
                  <span className={classes.dot} aria-hidden />
                  <span>{line.text}</span>
                </li>
              ))}
            </ol>
          )}
          {runUrl && (
            <a
              className={classes.link}
              href={runUrl}
              target="_blank"
              rel="noopener noreferrer"
            >
              Open the run in GitHub Actions
            </a>
          )}
        </div>
      )}
    </section>
  );
}
