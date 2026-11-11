import { useLayoutEffect, useRef, useState } from 'react';
import {
  Bar,
  Card,
  Collapse,
  Connector,
  Field,
  Row,
  Stage,
  Swap,
  Text,
  Window,
  type Act,
  type Point,
} from './kit';
import { Glyph, type GlyphName } from './icons';
import { brandLook } from './brandLook';
import { brandOverrides, useBrandIdentity } from '../identity/brandIdentity';
import type { BrandMode } from '../tokens/brandTokens';
import './CatalogSearchDemo.css';

// The sign-in page's product shot: the portal's catalog in its own window,
// set into the brand panel. Someone filters the catalog for "kafka", the
// list narrows to the one match (and the section under it comes up), they
// open Apache Kafka, and its entity page shows who owns it, the system it
// belongs to and how the three relate. Clicking Components in the sidebar
// goes back to a fresh catalog: the loop's reset.
//
// Layout: the fade crop, as its narrow design frames it (one gutter top and
// left, the window running off the right edge, its foot fading out). Here
// the right edge is the brand panel's own, and the foot sinks into the panel
// above the line under it.
//
// Real strings: the five sidebar items the portal really has, the page title,
// what is typed, the entity, and its owner and system with their labels (the
// graph repeats those three names, nothing new). Every other row, column,
// card title and node is placeholder.

type S = {
  focus: boolean;
  q: string;
  /** Rows the filter has taken out, by index */
  out: boolean[];
  page: 'catalog' | 'entity';
  /** The page is on its way out: dimmed, about to be replaced */
  dim: boolean;
  /** How many relation lines have drawn */
  edges: number;
};

const QUERY = 'kafka';
const ENTITY = 'Apache Kafka';
const OWNER = 'Data Team';
const SYSTEM = 'Data Platform';

// The catalog's rows: the name (a bar's width, or the entity), three more
// columns of placeholder, and whether the row matches the query.
const ROWS: {
  name: number | string;
  cols: [number, number, number];
  match?: boolean;
}[] = [
  { name: 92, cols: [58, 88, 40] },
  { name: 64, cols: [72, 96, 52] },
  { name: ENTITY, cols: [66, 90, 44], match: true },
  { name: 104, cols: [50, 84, 40] },
  { name: 76, cols: [62, 98, 56] },
  { name: 88, cols: [70, 86, 44] },
  { name: 58, cols: [54, 92, 40] },
  { name: 110, cols: [64, 88, 52] },
  { name: 72, cols: [58, 96, 44] },
  { name: 96, cols: [68, 84, 40] },
  { name: 84, cols: [52, 90, 56] },
  { name: 66, cols: [60, 94, 44] },
];
const KEPT = ROWS.map(() => false);
const GONE = ROWS.flatMap((r, i) => (r.match ? [] : [i]));
const NARROWED = ROWS.map(r => !r.match);

const NAV: { icon: GlyphName; label: string; selected?: boolean }[] = [
  { icon: 'home', label: 'Home' },
  { icon: 'components', label: 'Components', selected: true },
  { icon: 'apis', label: 'APIs' },
  { icon: 'resources', label: 'Resources' },
  { icon: 'templates', label: 'Templates' },
];

// The relations graph, in its own box's pixels: the entity and what it
// relates to. The owner and the system are the two the card above names.
const NODE = { width: 120, height: 28 };
const NODES: {
  icon: GlyphName;
  label: string | number;
  x: number;
  y: number;
  root?: boolean;
}[] = [
  { icon: 'components', label: ENTITY, x: 0, y: 36, root: true },
  { icon: 'group', label: OWNER, x: 152, y: 0 },
  { icon: 'system', label: SYSTEM, x: 152, y: 36 },
  { icon: 'resources', label: 52, x: 152, y: 72 },
];
const EDGES = NODES.length - 1;
const from: Point = {
  x: NODES[0].x + NODE.width,
  y: NODES[0].y + NODE.height / 2,
};
const to = (i: number): Point => ({
  x: NODES[i].x,
  y: NODES[i].y + NODE.height / 2,
});

const initial: S = {
  focus: false,
  q: '',
  out: KEPT,
  page: 'catalog',
  dim: false,
  edges: 0,
};
// The frame that tells the story on its own: the entity that was found
const POSTER: S = {
  focus: false,
  q: QUERY,
  out: NARROWED,
  page: 'entity',
  dim: false,
  edges: EDGES,
};

async function script(a: Act<S>) {
  await a.wait(700);

  // 1. Into the catalog's filter
  a.mark('search');
  await a.click({ at: 'search', x: 0.78, y: 0.55 });
  await a.set({ focus: true });
  await a.wait(250);

  // 2. "kafka": the rows that don't match leave, top to bottom in one quick
  // run, the one that does closes up under the header and the next section
  // comes up
  await a.type('q', QUERY, { interval: 110 });
  await a.wait(220);
  a.mark('narrow');
  await a.stagger(
    GONE,
    i => a.set(s => ({ out: s.out.map((o, j) => o || j === i) })),
    30,
  );
  await a.wait(1200);

  // 3. Open Apache Kafka, the fingertip just past its name
  a.mark('open');
  await a.move({ at: 'kafka-name', x: 1.14, y: 0.6 });
  await a.wait(220);
  await a.click();
  await a.set({ dim: true });
  await a.wait(100);
  await a.set({ page: 'entity', focus: false, dim: false });

  // 4. Its page: owner and system are there as it arrives, and the
  // relations draw out from the entity while the pointer gets out of the way
  a.mark('entity');
  const away = a.move('rest-entity');
  await a.wait(200);
  await a.stagger(
    NODES.slice(1).map((_, i) => i + 1),
    n => a.set({ edges: n }),
    110,
  );
  await away;
  // The lines take a second to land; then the finished page holds
  await a.wait(1000);
  a.mark('payoff');
  await a.wait(2600);

  // 5. Back to the catalog from the sidebar. The filter and the rows are put
  // back while the catalog is out of sight, so it returns as a fresh page.
  a.mark('reset');
  await a.click({ at: 'nav-components', x: 0.97, y: 0.6 });
  await a.set({ dim: true });
  await a.wait(100);
  await a.snap({ q: '', out: KEPT }, 'catalog');
  await a.set({ page: 'catalog', edges: 0, dim: false });
  await a.move('rest');
  await a.wait(150);
}

// Stage pixels. The window sits one gutter in from the stage's top and left
// and runs off its right edge and its foot.
const GUTTER = 32;
const SIDEBAR = 120;
/** The window's width in view at 1:1: a 533px brand panel less its 48px padding. */
const VIEW_W = 485;
/** The least of the window's width that keeps the story's words whole: the graph's named nodes end at 420. */
const VIEW_MIN_W = 432;
/** The least and most of the window's height to show: enough for the payoff, and no more than the pages hold. */
const VIEW_MIN_H = 340;
const VIEW_MAX_H = 520;
/** How far the window runs past the stage's right edge. */
const BLEED = 190;
/** How far the fading foot may run below the slot, towards the line under it (CSS px). */
const FOOT = 20;
/** Below this the type stops reading; above the other, it outgrows the host's own copy. */
const MIN_SCALE = 0.85;
const MAX_SCALE = 1.25;
/** A desktop window in view is never taller than it is wide. */
const VIEW_MAX_RATIO = 0.98;

/** The title's box stays one width, so a longer title is never cut while it arrives. */
const HEADING = { width: 160 };

type Frame = { scale: number; width: number; height: number };

/**
 * Fits the stage to its slot. The window keeps its left edge on the slot's
 * (the host's text column) and runs off the slot's right edge. A wider panel
 * draws it larger; a narrower one shows less of its width at the same size,
 * down to the width the story needs, and only then draws it smaller. A short
 * slot lowers the scale too. When the type would stop reading there is no
 * demo.
 */
function fit(view: number, height: number): Frame | null {
  const room = height + FOOT;
  const scale = Math.min(
    MAX_SCALE,
    Math.max(view / VIEW_W, Math.min(1, view / VIEW_MIN_W)),
    room / VIEW_MIN_H,
  );
  if (scale < MIN_SCALE) return null;
  const width = Math.ceil(view / scale);
  return {
    scale,
    width: GUTTER + width,
    height:
      GUTTER +
      Math.round(Math.min(VIEW_MAX_H, room / scale, width * VIEW_MAX_RATIO)),
  };
}

export interface CatalogSearchDemoProps {
  /** The portal theme the demo is shown in. */
  mode: BrandMode;
}

/**
 * Decorative. Fills its positioned parent (the slot): the window's top left
 * corner sits on the slot's, it runs off the slot's right edge and its foot
 * fades out just below the slot. One gutter of the stage (the window's
 * shadow) lies outside the slot, above and to the left. The host hides the
 * slot from assistive technology; nothing in it takes focus or the pointer.
 */
export default function CatalogSearchDemo({ mode }: CatalogSearchDemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const [frame, setFrame] = useState<Frame | null>(null);
  const overrides = brandOverrides(useBrandIdentity());
  useLayoutEffect(() => {
    const el = root.current;
    if (!el) return undefined;
    const measure = () => {
      const next = fit(el.clientWidth, el.clientHeight);
      setFrame(prev =>
        prev &&
        next &&
        prev.scale === next.scale &&
        prev.width === next.width &&
        prev.height === next.height
          ? prev
          : next,
      );
    };
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return (
    <div ref={root} className="csd" aria-hidden="true">
      {frame && (
        <div
          className="csd-crop"
          style={{
            top: -GUTTER * frame.scale,
            bottom: -FOOT,
            left: -GUTTER * frame.scale,
          }}
        >
          <div style={{ width: frame.width * frame.scale }}>
            <Stage
              width={frame.width}
              height={frame.height}
              fill
              theme={mode}
              tokens={brandLook(mode, overrides)}
              initial={initial}
              poster={POSTER}
              script={script}
              cursor={{ at: 'rest', ripple: true }}
            >
              {s => <Scene s={s} width={frame.width} height={frame.height} />}
            </Stage>
          </div>
        </div>
      )}
    </div>
  );
}

function Scene({ s, width, height }: { s: S; width: number; height: number }) {
  return (
    <>
      <Window
        className="csd-window"
        style={{
          left: GUTTER,
          top: GUTTER,
          width: width - GUTTER + BLEED,
          height,
        }}
        sidebar={<Sidebar />}
        sidebarWidth={SIDEBAR}
        lead={
          <Swap
            id={s.page}
            duration={300}
            className="csd-heading"
            style={HEADING}
          >
            {s.page === 'catalog' ? 'Catalog' : ENTITY}
          </Swap>
        }
        body={{ 'data-crop': true }}
      >
        <div className="csd-pages" data-dim={s.dim || undefined}>
          <div
            className="csd-pg"
            data-target="catalog"
            data-show={s.page === 'catalog' || undefined}
          >
            <Catalog s={s} />
          </div>
          <div className="csd-pg" data-show={s.page === 'entity' || undefined}>
            <Entity s={s} />
          </div>
        </div>
      </Window>
      {/* Where the cursor waits: clear surface, on a path that crosses nothing
          it could be mistaken for pointing at */}
      <span
        className="csd-rest"
        data-target="rest"
        style={{ left: GUTTER + 292, top: GUTTER + 164 }}
      />
      <span
        className="csd-rest"
        data-target="rest-entity"
        style={{ left: GUTTER + 312, top: GUTTER + 12 }}
      />
    </>
  );
}

function Sidebar() {
  return (
    <div className="csd-nav">
      {NAV.map(n => (
        <div
          key={n.label}
          className="csd-nav__item"
          data-selected={n.selected || undefined}
          data-target={n.selected ? 'nav-components' : undefined}
          data-cursor={n.selected ? 'hand' : undefined}
        >
          <Glyph name={n.icon} />
          <Text className="csd-nav__label">{n.label}</Text>
        </div>
      ))}
      <div className="csd-nav__rule" />
      {/* The rest of the portal's sidebar, trailing off */}
      <div className="csd-nav__more">
        {[52, 44, 60, 38, 56, 42].map(w => (
          <div key={w} className="csd-nav__item">
            <Bar w={16} h={16} r={4} tone={3} />
            <Bar w={w} h={6} tone={3} />
          </div>
        ))}
      </div>
    </div>
  );
}

function Cols({ widths, tone }: { widths: number[]; tone: 2 | 4 }) {
  return (
    <span className="csd-cols">
      {widths.map((w, i) => (
        <Bar key={i} w={w} h={6} tone={tone} />
      ))}
    </span>
  );
}

// Placeholder lines, long enough to carry every page past the window's foot
const LINES = Array.from({ length: 17 }, (_, i) => ({
  name: 96 + ((i * 37) % 60),
  meta: 44 + ((i * 23) % 24),
}));

/**
 * A section of placeholder: the page carrying on under what the story is
 * about. Plain, a list of lines each with a second mark at its end; with
 * `tiles`, a list of tiled items. The two pages take one each, so they are
 * different lists and no line of one lands on a line of the other.
 */
function Section({ tiles }: { tiles?: boolean }) {
  return (
    <Card pad="small" gap={tiles ? 12 : 14}>
      <Bar w={tiles ? 64 : 44} h={7} tone={4} />
      {LINES.map((line, i) => (
        <div key={i} className="csd-line">
          {tiles && <Bar w={16} h={16} r={4} tone={2} />}
          <Bar w={line.name} h={6} tone={3} />
          {!tiles && (
            <Bar className="csd-line__end" w={line.meta} h={6} tone={2} />
          )}
        </div>
      ))}
    </Card>
  );
}

function Catalog({ s }: { s: S }) {
  return (
    <div className="csd-catalog">
      <Field
        className="csd-search"
        value={s.q}
        focused={s.focus}
        leading={<Glyph name="search" className="csd-search__icon" />}
        box={{ 'data-target': 'search' }}
      />
      <div className="csd-table">
        <Row
          className="csd-row csd-row--head"
          title={<Bar w={36} h={6} tone={4} />}
        >
          <Cols widths={[44, 38, 30]} tone={4} />
        </Row>
        {ROWS.map((r, i) => {
          const entity = r.name === ENTITY;
          return (
            <Collapse key={i} open={!s.out[i]}>
              <Row
                className="csd-row"
                data-entity={entity || undefined}
                data-target={entity ? 'kafka' : undefined}
                data-cursor={
                  entity && s.page === 'catalog' ? 'hand' : undefined
                }
                title={
                  typeof r.name === 'string' ? (
                    <Text className="csd-name" data-target="kafka-name">
                      {r.name}
                    </Text>
                  ) : (
                    <Bar w={r.name} h={7} tone={3} />
                  )
                }
              >
                <Cols widths={r.cols} tone={2} />
              </Row>
            </Collapse>
          );
        })}
      </div>
      <Section />
    </div>
  );
}

function Entity({ s }: { s: S }) {
  return (
    <div className="csd-entity">
      <Card pad="small">
        <div className="csd-fields">
          <div className="csd-field">
            <Text className="csd-label">Owner</Text>
            <Text className="csd-value">{OWNER}</Text>
          </div>
          <div className="csd-field">
            <Text className="csd-label">System</Text>
            <Text className="csd-value">{SYSTEM}</Text>
          </div>
          {[
            [30, 52],
            [44, 38],
          ].map(([label, value]) => (
            <div key={label} className="csd-field csd-field--bar">
              <span className="csd-label">
                <Bar w={label} h={6} tone={2} />
              </span>
              <span className="csd-value">
                <Bar w={value} h={7} tone={3} />
              </span>
            </div>
          ))}
        </div>
      </Card>
      <Card pad="small" gap={12}>
        <Bar w={56} h={7} tone={4} />
        <div className="csd-graph">
          {NODES.slice(1).map((n, i) => (
            <Connector
              key={n.icon}
              className="csd-edge"
              from={from}
              to={to(i + 1)}
              route="curve"
              dots="none"
              show={s.edges > i}
            />
          ))}
          {NODES.map(n => (
            <div
              key={n.icon}
              className="csd-node"
              data-root={n.root || undefined}
              style={{
                left: n.x,
                top: n.y,
                width: NODE.width,
                height: NODE.height,
              }}
            >
              <Glyph name={n.icon} size={14} />
              {typeof n.label === 'string' ? (
                <Text className="csd-node__label">{n.label}</Text>
              ) : (
                <Bar w={n.label} h={6} tone={3} />
              )}
            </div>
          ))}
        </div>
      </Card>
      <Section tiles />
    </div>
  );
}
