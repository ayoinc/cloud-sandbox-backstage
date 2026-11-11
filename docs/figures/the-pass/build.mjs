// Builds the-pass.html: an interactive figure of a template run on the
// Cloudflare deployment, drawn as a service lift between a counter and a
// workshop. The portal serves it at /figures/the-pass.html.
//
//   node docs/figures/the-pass/build.mjs
//   node docs/figures/the-pass/build.mjs --out /tmp/pass --theme light
//
// The page follows the reader's light or dark preference. The drawing kit in
// ../kit is the Anatomy kit (MIT, see ../kit/LICENSE).
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import * as k from '../kit/iso-kit.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const kitScript = () =>
  readFileSync(join(HERE, '..', 'kit', 'iso-kit.mjs'), 'utf8').replace(
    /^export /gm,
    '',
  );

// --- The model: one real run, as the portal reported it -------------------
// Architecture Decision Records template, 11 November 2026: queued for 8 s,
// 62 s preparing the runner, four steps, finished at 1:27.
const RUN = {
  queuedUntil: 8,
  preparedAt: 70,
  handedOverAt: 72,
  stepSeconds: 3,
  steps: 4,
  packedAt: 85,
  raisedAt: 86,
  finishedAt: 87,
};
const STEPS_DONE = RUN.handedOverAt + RUN.steps * RUN.stepSeconds; // 84

const WIDTH = 640;
const HEIGHT = 420;

// --- The world -------------------------------------------------------------
const PLATE = { x: -128, y: -52, w: 262, d: 108, r: 8 };
const PLATE_H = 10;
const FOOT_H = 5;

// The mast the lift runs on, with the winch on its head.
const MAST_Y = -30;
const POSTS = [-13, 13];
const POST_R = 2.6;
const HEAD_Z = 126;
const HEAD = { x: -19, y: MAST_Y - 6, w: 38, d: 12, r: 2 };
const DRUM = [0, MAST_Y];
const DRUM_R = 5.2;

// The lift: a carriage on the posts and a platform out in front of it.
const BENCH_TOP = 16;
const COUNTER_TOP = 92;
const LOW = BENCH_TOP;
const HIGH = COUNTER_TOP;
// It reaches back to the carriage it hangs from.
const PLATFORM = { x: -17, y: -27, w: 34, d: 45, r: 2 };
const PLATFORM_H = 3;
const CARRIAGE = { x: -17, y: MAST_Y - 3.5, w: 34, d: 7, r: 1.5 };
const CARRIAGE_H = 16;

// The counterweight behind the mast goes the other way.
const WEIGHT = { x: -9, y: MAST_Y - 17, w: 18, d: 8, r: 1.5 };
const WEIGHT_H = 20;
const WEIGHT_LOW = 6;

// The workshop bench, with one lamp for each step.
const BENCH = { x: -120, y: -26, w: 96, d: 50, r: 3 };
const LAMP_X = [-104, -88, -72, -56];
const LAMP_Y = -12;
const INBOX = { x: -45, y: -2, w: 16, d: 14, r: 1.5 };

// The counter, with a rack the finished work is shelved in.
const COUNTER = { x: 21, y: -26, w: 104, d: 50, r: 3 };
const COUNTER_H = 6;
const SLOTS = [44, 68, 92];
const SLOT_Y = -6;

// What travels: a ticket going down, a box coming back.
const TICKET = { x: -6, y: -8, w: 12, d: 9, r: 1 };
const TICKET_H = 1.4;
const BOX = { x: -8, y: -14, w: 16, d: 16, r: 1.5 };
const BOX_H = 11;
const BOX_FROM_X = -45 - BOX.x - BOX.w / 2 + 8; // over the inbox
const BOX_TO_X = SLOTS[0];

const P = k.fitProjection(
  [
    ...k.boxCorners(PLATE, -PLATE_H - FOOT_H, 0),
    [0, MAST_Y, HEAD_Z + 16],
    [COUNTER.x + COUNTER.w, COUNTER.y + COUNTER.d, COUNTER_TOP + 14],
  ],
  WIDTH,
  HEIGHT,
  { pad: 22, azimuth: 40 },
);

const at = point => k.iso(point, P);
const S = (paths, style) => k.solidSvg(paths, style);
const L = (d, style) => k.lineSvg(d, style);
const D = (points, style) => k.dotsSvg(points, style);
const byDepth = points =>
  [...points].sort(
    (a, b) => k.depthOf([a[0], a[1], 0], P) - k.depthOf([b[0], b[1], 0], P),
  );

function plate() {
  const out = [
    `<path class="iso-halo" d="${k.haloOf(
      PLATE,
      -PLATE_H - FOOT_H,
      PLATE_H,
      P,
    )}"/>`,
  ];
  for (const [x, y] of byDepth(k.corners(PLATE, 20))) {
    out.push(
      S(k.cylinder(x, y, 7, -PLATE_H - FOOT_H, 1.6, P, 28), { tone: 'lo' }),
    );
    out.push(
      S(k.cylinder(x, y, 5.4, -PLATE_H - FOOT_H + 1.6, FOOT_H - 1.6, P, 28), {
        tone: 'mid',
      }),
    );
  }
  out.push(S(k.slabOf(PLATE, -PLATE_H, PLATE_H, P, 8, 1.6), { tone: 'mid' }));
  out.push(L(k.planOutline(k.insetPlan(PLATE, 5), 0, P), { tone: 'lo' }));
  const screws = k.corners(PLATE, 10);
  out.push(
    L(screws.map(([x, y]) => k.ring(x, y, 2.2, 0, P, 16)).join(''), {
      tone: 'lo',
    }),
  );
  out.push(
    D(
      screws.map(([x, y]) => at([x, y, 0])),
      { size: 0.5 },
    ),
  );
  // A ruler along the front, and the maker's plate.
  const strip = { x: -112, y: PLATE.y + PLATE.d - 14, w: 150, d: 7, r: 1 };
  out.push(S(k.slabOf(strip, 0, 0.6, P, 3), { tone: 'lo', crease: 'none' }));
  const ticks = k.topTicks(
    strip.x + 4,
    strip.x + strip.w - 4,
    4,
    5,
    strip.y + 0.8,
    0.6,
    [2, 3.6],
    P,
  );
  out.push(L(ticks.minor, { tone: 'lo' }), L(ticks.major, { tone: 'mid' }));
  out.push(
    D(
      [
        at([strip.x + 2, strip.y + 3.5, 0.6]),
        at([strip.x + strip.w - 2, strip.y + 3.5, 0.6]),
      ],
      { size: 0.45 },
    ),
  );
  const label = { x: 62, y: PLATE.y + PLATE.d - 15, w: 44, d: 9, r: 1 };
  out.push(S(k.slabOf(label, 0, 0.7, P, 3), { tone: 'lo', crease: 'none' }));
  out.push(
    L(
      [3, 5.4]
        .map(dy =>
          k.lineOnTop(
            [label.x + 4, label.y + dy],
            [label.x + label.w - 4, label.y + dy],
            0.7,
            P,
          ),
        )
        .join(''),
      { tone: 'faint', free: true },
    ),
  );
  out.push(
    D(
      [
        at([label.x + 1.8, label.y + 4.5, 0.7]),
        at([label.x + label.w - 1.8, label.y + 4.5, 0.7]),
      ],
      { size: 0.4 },
    ),
  );
  return out.join('');
}

function weight() {
  const out = [];
  out.push(S(k.slabOf(WEIGHT, 0, WEIGHT_H, P, 3, 0.5), { tone: 'mid' }));
  out.push(
    L([6, 13].map(z => k.sideSeam(WEIGHT, z, P, 3)).join(''), {
      tone: 'faint',
    }),
  );
  out.push(
    S(k.cylinder(0, WEIGHT.y + WEIGHT.d / 2, 1.6, WEIGHT_H, 2, P, 14), {
      tone: 'mid',
    }),
  );
  return out.join('');
}

function mastFoot() {
  const out = [];
  const foot = { x: -21, y: MAST_Y - 7, w: 42, d: 14, r: 2 };
  out.push(S(k.slabOf(foot, 0, 4, P, 4, 0.5), { tone: 'mid' }));
  out.push(
    D(
      [
        at([foot.x + 3, foot.y + 3, 4]),
        at([foot.x + foot.w - 3, foot.y + 3, 4]),
        at([foot.x + 3, foot.y + foot.d - 3, 4]),
        at([foot.x + foot.w - 3, foot.y + foot.d - 3, 4]),
      ],
      { size: 0.45 },
    ),
  );
  return out.join('');
}

function post(x) {
  const out = [];
  out.push(
    S(k.cylinder(x, MAST_Y, POST_R + 1.4, 4, 3, P, 20), { tone: 'mid' }),
  );
  out.push(
    S(k.cylinder(x, MAST_Y, POST_R, 7, HEAD_Z - 7, P, 24), {
      tone: 'mid',
      crease: 'none',
    }),
  );
  // Height marks: a band every quarter of the travel.
  out.push(
    L([35, 54, 73].map(z => k.sideArc(x, MAST_Y, POST_R, z, P, 14)).join(''), {
      tone: 'faint',
    }),
  );
  return out.join('');
}

function head() {
  const out = [];
  // An arm out the back carries the counterweight's cable.
  const arm = {
    x: -4,
    y: WEIGHT.y - 1,
    w: 8,
    d: HEAD.y - WEIGHT.y + 3,
    r: 1.2,
  };
  out.push(S(k.slabOf(arm, HEAD_Z, 4, P, 3, 0.4), { tone: 'mid' }));
  out.push(D([at([0, WEIGHT.y + WEIGHT.d / 2, HEAD_Z + 4])], { size: 0.45 }));
  out.push(S(k.slabOf(HEAD, HEAD_Z, 5, P, 4, 0.6), { tone: 'mid' }));
  out.push(
    D(
      POSTS.map(x => at([x, MAST_Y, HEAD_Z + 5])),
      { size: 0.5 },
    ),
  );
  // The winch drum, knurled, with a mark that turns as the lift moves.
  out.push(
    S(k.cylinder(DRUM[0], DRUM[1], DRUM_R + 1.2, HEAD_Z + 5, 1.4, P, 28), {
      tone: 'mid',
    }),
  );
  out.push(
    S(k.cylinder(DRUM[0], DRUM[1], DRUM_R, HEAD_Z + 6.4, 6, P, 32), {
      tone: 'mid',
    }),
  );
  out.push(
    L(k.knurl(DRUM[0], DRUM[1], DRUM_R, HEAD_Z + 6.4, HEAD_Z + 12.4, 30, P), {
      tone: 'lo',
    }),
  );
  out.push(
    L(k.ring(DRUM[0], DRUM[1], 1.4, HEAD_Z + 12.4, P, 14), { tone: 'mid' }),
  );
  return out.join('');
}

const DRUM_TOP = HEAD_Z + 12.4;
const drumMark = turn => {
  const angle = turn * Math.PI * 2;
  return k.lineOnTop(
    [DRUM[0], DRUM[1]],
    [
      DRUM[0] + Math.sin(angle) * (DRUM_R - 0.8),
      DRUM[1] - Math.cos(angle) * (DRUM_R - 0.8),
    ],
    DRUM_TOP,
    P,
  );
};
// The cable runs from the underside of the head to the top of the carriage.
const cable = lift => k.rise([0, MAST_Y + 5], lift + CARRIAGE_H, HEAD_Z, P);
const weightCable = lift =>
  k.rise(
    [0, WEIGHT.y + WEIGHT.d / 2],
    WEIGHT_LOW + (HIGH - lift) + WEIGHT_H + 2,
    HEAD_Z,
    P,
  );

/** The lift, built at height 0 and moved by the page. */
function lift() {
  const out = [];
  // Carriage: the plate that rides the posts, with its guide blocks.
  out.push(
    S(k.slabOf(CARRIAGE, -2, CARRIAGE_H + 2, P, 3, 0.5), { tone: 'mid' }),
  );
  for (const x of POSTS) {
    for (const z of [0, CARRIAGE_H - 5]) {
      out.push(
        S(
          k.slabOf(
            { x: x - 4.2, y: MAST_Y - 4.6, w: 8.4, d: 9.2, r: 1.5 },
            z,
            5,
            P,
            3,
            0.4,
          ),
          { tone: 'mid' },
        ),
      );
    }
  }
  out.push(D([at([0, MAST_Y + 5, CARRIAGE_H])], { size: 0.6, tone: 'hi' }));
  // Platform: a tray with a raised lip, braced to the carriage.
  out.push(
    `<path class="iso-halo" d="${k.haloOf(
      k.insetPlan(PLATFORM, 2),
      -PLATFORM_H,
      0.1,
      P,
    )}" style="filter:blur(3px)"/>`,
  );
  out.push(
    S(k.slabOf(PLATFORM, -PLATFORM_H, PLATFORM_H, P, 4, 0.6), { tone: 'mid' }),
  );
  out.push(
    L(k.planOutline(k.insetPlan(PLATFORM, 2.4), 0, P, 4), { tone: 'lo' }),
  );
  out.push(
    D(
      k.corners(PLATFORM, 4.6).map(([x, y]) => at([x, y, 0])),
      { size: 0.4, tone: 'lo' },
    ),
  );
  return out.join('');
}

function bench() {
  const out = [
    `<path class="iso-halo" d="${k.haloOf(
      k.insetPlan(BENCH, 2),
      0,
      0.1,
      P,
    )}" style="filter:blur(4px)"/>`,
  ];
  // Legs, then the top.
  for (const [x, y] of byDepth(k.corners(BENCH, 6))) {
    out.push(
      S(
        k.slabOf(
          { x: x - 3, y: y - 3, w: 6, d: 6, r: 1 },
          0,
          BENCH_TOP - 4,
          P,
          2,
        ),
        {
          tone: 'mid',
        },
      ),
    );
  }
  out.push(
    S(k.slabOf(BENCH, BENCH_TOP - 4, 4, P, 5, 0.8), {
      tone: 'mid',
      inner: L(k.sideSeam(BENCH, BENCH_TOP - 2, P, 5), { tone: 'faint' }),
    }),
  );
  // A rail the step lamps stand on.
  const rail = { x: LAMP_X[0] - 8, y: LAMP_Y - 5, w: 64, d: 10, r: 1.5 };
  out.push(S(k.slabOf(rail, BENCH_TOP, 1.6, P, 3, 0.4), { tone: 'mid' }));
  out.push(
    D(
      [
        at([rail.x + 2.4, rail.y + 5, BENCH_TOP + 1.6]),
        at([rail.x + rail.w - 2.4, rail.y + 5, BENCH_TOP + 1.6]),
      ],
      { size: 0.4 },
    ),
  );
  // A vise at the back and a tool tray at the front: it is a workshop.
  const vise = { x: -112, y: 6, w: 16, d: 12, r: 1.5 };
  out.push(S(k.slabOf(vise, BENCH_TOP, 6, P, 3, 0.5), { tone: 'mid' }));
  out.push(
    S(
      k.slabOf(
        { x: vise.x + 2, y: vise.y + 3, w: 4, d: 6, r: 0.8 },
        BENCH_TOP + 6,
        4,
        P,
        2,
      ),
      {
        tone: 'mid',
      },
    ),
    S(
      k.slabOf(
        { x: vise.x + 9, y: vise.y + 3, w: 4, d: 6, r: 0.8 },
        BENCH_TOP + 6,
        4,
        P,
        2,
      ),
      {
        tone: 'mid',
      },
    ),
  );
  out.push(
    S(k.cylinder(vise.x + 19, vise.y + 6, 2.2, BENCH_TOP + 2, 3, P, 16), {
      tone: 'mid',
    }),
    L(
      k.knurl(
        vise.x + 19,
        vise.y + 6,
        2.2,
        BENCH_TOP + 2,
        BENCH_TOP + 5,
        14,
        P,
      ),
      {
        tone: 'lo',
      },
    ),
  );
  const tray = { x: -86, y: 8, w: 30, d: 12, r: 1.5 };
  out.push(
    S(k.slabOf(tray, BENCH_TOP, 1.2, P, 3), { tone: 'lo', crease: 'none' }),
  );
  out.push(
    L(
      [3, 6, 9]
        .map(dy =>
          k.lineOnTop(
            [tray.x + 3, tray.y + dy],
            [tray.x + tray.w - 3, tray.y + dy],
            BENCH_TOP + 1.2,
            P,
          ),
        )
        .join(''),
      { tone: 'faint', free: true },
    ),
  );
  // The inbox the ticket is handed onto, next to the lift.
  out.push(
    S(k.slabOf(INBOX, BENCH_TOP, 1, P, 3), { tone: 'lo', crease: 'none' }),
  );
  out.push(
    L(k.planOutline(k.insetPlan(INBOX, 1.6), BENCH_TOP + 1, P, 3), {
      tone: 'faint',
    }),
  );
  return out.join('');
}

/** One step lamp: a collar, a post and a lens, lit or not. */
function lamp(x, lit) {
  const z = BENCH_TOP + 1.6;
  return [
    S(k.cylinder(x, LAMP_Y, 3.6, z, 1.2, P, 20), { tone: 'mid' }),
    S(k.cylinder(x, LAMP_Y, 2.2, z + 1.2, 5, P, 18), {
      tone: 'mid',
      crease: 'none',
    }),
    S(k.cylinder(x, LAMP_Y, 2.9, z + 6.2, 2.6, P, 20), {
      tone: lit ? 'hi' : 'mid',
      lit,
    }),
  ].join('');
}

function counter() {
  const out = [];
  // Two legs at the far end; the near end is bracketed to the mast.
  for (const [x, y] of byDepth([
    [COUNTER.x + COUNTER.w - 8, COUNTER.y + 8],
    [COUNTER.x + COUNTER.w - 8, COUNTER.y + COUNTER.d - 8],
  ])) {
    out.push(
      S(k.cylinder(x, y, 4.4, 0, 2, P, 20), { tone: 'mid' }),
      S(k.cylinder(x, y, 2.6, 2, COUNTER_TOP - COUNTER_H - 2, P, 20), {
        tone: 'mid',
        crease: 'none',
      }),
      L(k.sideArc(x, y, 2.6, 46, P, 14), { tone: 'faint' }),
    );
  }
  const bracket = { x: COUNTER.x - 6, y: MAST_Y + 3, w: 12, d: 6, r: 1 };
  out.push(
    S(k.slabOf(bracket, COUNTER_TOP - COUNTER_H - 5, 5, P, 2, 0.4), {
      tone: 'mid',
    }),
  );
  out.push(
    S(k.slabOf(COUNTER, COUNTER_TOP - COUNTER_H, COUNTER_H, P, 5, 0.9), {
      tone: 'mid',
      inner: L(k.sideSeam(COUNTER, COUNTER_TOP - 2, P, 5), { tone: 'faint' }),
    }),
  );
  out.push(
    L(k.planOutline(k.insetPlan(COUNTER, 3.5), COUNTER_TOP, P, 5), {
      tone: 'faint',
    }),
  );
  // The rack: a back rail and three cradles.
  const rail = {
    x: SLOTS[0] - 12,
    y: SLOT_Y - 13,
    w: SLOTS[2] - SLOTS[0] + 24,
    d: 3,
    r: 0.8,
  };
  out.push(S(k.slabOf(rail, COUNTER_TOP, 9, P, 2, 0.4), { tone: 'mid' }));
  for (const x of SLOTS) {
    const cradle = { x: x - 10, y: SLOT_Y - 9, w: 20, d: 20, r: 1.5 };
    out.push(
      S(k.slabOf(cradle, COUNTER_TOP, 0.8, P, 3), {
        tone: 'lo',
        crease: 'none',
      }),
    );
    out.push(
      L(k.planOutline(k.insetPlan(cradle, 1.6), COUNTER_TOP + 0.8, P, 3), {
        tone: 'faint',
      }),
    );
  }
  // Work shelved earlier.
  for (const x of [SLOTS[1], SLOTS[2]]) {
    out.push(box(x, COUNTER_TOP + 0.8, false));
  }
  // A call bell and a ticket spike at the front of the counter.
  const bell = [COUNTER.x + 14, COUNTER.y + COUNTER.d - 9];
  out.push(
    S(k.cylinder(bell[0], bell[1], 4.4, COUNTER_TOP, 1, P, 24), {
      tone: 'mid',
    }),
    S(k.cylinder(bell[0], bell[1], 3.6, COUNTER_TOP + 1, 2.6, P, 24), {
      tone: 'mid',
    }),
    S(k.cylinder(bell[0], bell[1], 0.9, COUNTER_TOP + 3.6, 1.6, P, 10), {
      tone: 'mid',
    }),
  );
  const spike = [COUNTER.x + 30, COUNTER.y + COUNTER.d - 9];
  out.push(
    S(k.cylinder(spike[0], spike[1], 3, COUNTER_TOP, 1, P, 18), {
      tone: 'mid',
    }),
    L(k.rise(spike, COUNTER_TOP + 1, COUNTER_TOP + 9, P), { tone: 'mid' }),
    D(
      [
        at([spike[0], spike[1], COUNTER_TOP + 1]),
        at([spike[0], spike[1], COUNTER_TOP + 9]),
      ],
      { size: 0.4 },
    ),
  );
  return out.join('');
}

/** A finished piece of work: a lidded box. Built at `[x, SLOT_Y]`. */
function box(x, z, lit) {
  const plan = {
    x: x + BOX.x,
    y: SLOT_Y + BOX.y + 6,
    w: BOX.w,
    d: BOX.d,
    r: BOX.r,
  };
  return [
    S(k.slabOf(plan, z, BOX_H, P, 3, 0.5), {
      // Only the piece in transit is drawn strong: it is what to follow.
      tone: lit ? 'hi' : 'mid',
      crease: lit ? 'faint' : 'lo',
      lit,
      inner: L(k.sideSeam(plan, z + BOX_H - 3, P, 3), { tone: 'lo' }),
    }),
    L(k.planOutline(k.insetPlan(plan, 2.2), z + BOX_H, P, 3), {
      tone: lit ? 'mid' : 'faint',
    }),
  ].join('');
}

function ticket() {
  return [
    S(k.slabOf(TICKET, 0, TICKET_H, P, 2), { tone: 'hi', lit: true }),
    L(
      [3, 5.4]
        .map(dy =>
          k.lineOnTop(
            [TICKET.x + 2, TICKET.y + dy],
            [TICKET.x + TICKET.w - 2, TICKET.y + dy],
            TICKET_H,
            P,
          ),
        )
        .join(''),
      { tone: 'mid', free: true },
    ),
  ].join('');
}

// --- The run, as positions -------------------------------------------------
// Shared by the build (for the first frame) and the page (for every frame).
function stateAt(t, RUN, LOW, HIGH, STEPS_DONE) {
  const ease = x => {
    const u = Math.min(1, Math.max(0, x));
    return u * u * (3 - 2 * u);
  };
  const between = (from, to) => ease((t - from) / (to - from));
  const down = between(RUN.queuedUntil, RUN.preparedAt);
  const up = between(RUN.packedAt, RUN.raisedAt);
  const lift = HIGH - (HIGH - LOW) * (down - up);
  const stepsLit =
    t < RUN.handedOverAt
      ? 0
      : Math.min(
          RUN.steps,
          Math.floor((t - RUN.handedOverAt) / RUN.stepSeconds) + 1,
        );
  let phase = 'Queued in GitHub Actions';
  if (t >= RUN.queuedUntil) phase = 'Preparing the runner';
  if (t >= RUN.preparedAt) phase = 'Starting the template';
  if (t >= RUN.handedOverAt)
    phase = 'Step ' + Math.min(RUN.steps, stepsLit) + ' of ' + RUN.steps;
  if (t >= STEPS_DONE) phase = 'Reporting back';
  if (t >= RUN.finishedAt) phase = 'Finished';
  return {
    lift,
    stepsLit: t >= STEPS_DONE ? RUN.steps : stepsLit,
    // The ticket rides down, then is handed onto the inbox.
    ticketOut: between(RUN.preparedAt, RUN.handedOverAt),
    // The box comes off the bench, rides up, and is shelved.
    boxShown: t >= STEPS_DONE,
    boxOn: between(STEPS_DONE, RUN.packedAt),
    boxShelved: between(RUN.raisedAt, RUN.finishedAt),
    phase,
  };
}

const first = stateAt(0, RUN, LOW, HIGH, STEPS_DONE);
const TICKET_TO_X = INBOX.x + INBOX.w / 2 - (TICKET.x + TICKET.w / 2);
const TICKET_TO_Y = INBOX.y + INBOX.d / 2 - (TICKET.y + TICKET.d / 2);

const svg = k.figureSvg({
  width: WIDTH,
  height: HEIGHT,
  label:
    'A service lift between a counter and a workshop bench below it. A ticket rides the lift down from the counter, is handed onto the bench, four lamps on the bench light one after another, and a box rides back up to be shelved in a rack on the counter. It shows a template run on the Cloudflare deployment: the Worker hands the work to GitHub Actions and the result comes back.',
  body: [
    plate(),
    `<g data-part="weight" transform="${k.translateAlong(P, [
      0,
      0,
      WEIGHT_LOW + (HIGH - first.lift),
    ])}">${weight()}</g>`,
    `<path data-part="weight-cable" class="iso-line" data-tone="lo" d="${weightCable(
      first.lift,
    )}"/>`,
    mastFoot(),
    bench(),
    ...LAMP_X.map(
      (x, index) =>
        `<g data-lamp="${index}">${lamp(
          x,
          false,
        )}</g><g data-lamp-lit="${index}" style="display:none">${lamp(
          x,
          true,
        )}</g>`,
    ),
    `<g data-part="ticket-bench" style="display:none" transform="${k.translateAlong(
      P,
      [TICKET_TO_X, TICKET_TO_Y, BENCH_TOP + 1],
    )}">${ticket()}</g>`,
    ...byDepth(POSTS.map(x => [x, MAST_Y])).map(([x]) => post(x)),
    `<path data-part="cable" class="iso-line" data-tone="mid" d="${cable(
      first.lift,
    )}"/>`,
    `<g data-part="lift" transform="${k.translateAlong(P, [
      0,
      0,
      first.lift,
    ])}">${lift()}</g>`,
    `<g data-part="ticket" transform="${k.translateAlong(P, [
      0,
      0,
      first.lift,
    ])}">${ticket()}</g>`,
    `<g data-part="box-low" style="display:none">${box(0, 0, true)}</g>`,
    head(),
    `<path data-part="drum-mark" class="iso-line" data-tone="hi" data-free="" d="${drumMark(
      0,
    )}" style="stroke-width:1"/>`,
    counter(),
    `<g data-part="box-high" style="display:none">${box(0, 0, true)}</g>`,
  ],
});

const live = `
const P = ${JSON.stringify(P)};
const RUN = ${JSON.stringify(RUN)};
const LOW = ${LOW}, HIGH = ${HIGH}, STEPS_DONE = ${STEPS_DONE};
const HEAD_Z = ${HEAD_Z}, CARRIAGE_H = ${CARRIAGE_H}, MAST_Y = ${MAST_Y};
const WEIGHT_LOW = ${WEIGHT_LOW}, WEIGHT_H = ${WEIGHT_H}, WEIGHT_AT = ${
  WEIGHT.y + WEIGHT.d / 2
};
const DRUM = ${JSON.stringify(
  DRUM,
)}, DRUM_R = ${DRUM_R}, DRUM_TOP = ${DRUM_TOP};
const BENCH_TOP = ${BENCH_TOP}, COUNTER_TOP = ${COUNTER_TOP};
const TICKET_TO = [${TICKET_TO_X}, ${TICKET_TO_Y}];
const BOX_FROM_X = ${BOX_FROM_X}, BOX_TO_X = ${BOX_TO_X}, SLOT_Y = ${SLOT_Y};
const stateAt = ${stateAt.toString()};
const drumMark = ${drumMark.toString().replace('k.lineOnTop', 'lineOnTop')};

const stage = document.querySelector(".iso-stage");
const svg = stage.querySelector("svg");
const part = (name) => svg.querySelector('[data-part="' + name + '"]');
const liftEl = part("lift"), ticketEl = part("ticket"), ticketBench = part("ticket-bench");
const boxLow = part("box-low"), boxHigh = part("box-high");
const weightEl = part("weight"), cableEl = part("cable"), weightCableEl = part("weight-cable"), markEl = part("drum-mark");
const lamps = [...svg.querySelectorAll("[data-lamp]")], lampsLit = [...svg.querySelectorAll("[data-lamp-lit]")];
const readout = document.querySelector("[data-readout]");
const still = matchMedia("(prefers-reduced-motion: reduce)");
const show = (element, on) => { const value = on ? "" : "none"; if (element.style.display !== value) element.style.display = value; };
const clock = (t) => Math.floor(t / 60) + ":" + String(Math.floor(t % 60)).padStart(2, "0");
// The box sits 6 back from the slot line on the lift, as it does in the rack.
const BOX_ON_LIFT_Y = -SLOT_Y - 6;

function draw(t) {
  const s = stateAt(t, RUN, LOW, HIGH, STEPS_DONE);
  liftEl.setAttribute("transform", translateAlong(P, [0, 0, s.lift]));
  weightEl.setAttribute("transform", translateAlong(P, [0, 0, WEIGHT_LOW + (HIGH - s.lift)]));
  cableEl.setAttribute("d", rise([0, MAST_Y + 5], s.lift + CARRIAGE_H, HEAD_Z, P));
  weightCableEl.setAttribute("d", rise([0, WEIGHT_AT], WEIGHT_LOW + (HIGH - s.lift) + WEIGHT_H + 2, HEAD_Z, P));
  markEl.setAttribute("d", drumMark((HIGH - s.lift) / (2 * Math.PI * DRUM_R)));

  // The ticket: on the lift until it is handed over, then on the inbox.
  const handed = s.ticketOut >= 1;
  show(ticketEl, !handed);
  show(ticketBench, handed);
  if (!handed) ticketEl.setAttribute("transform", translateAlong(P, [TICKET_TO[0] * s.ticketOut, TICKET_TO[1] * s.ticketOut, s.lift + (BENCH_TOP + 1 - LOW) * s.ticketOut]));

  lamps.forEach((lamp, index) => show(lamp, index >= s.stepsLit));
  lampsLit.forEach((lamp, index) => show(lamp, index < s.stepsLit));

  // The box: off the bench onto the lift, up, then along the counter.
  const shelving = s.boxShelved > 0;
  show(boxLow, s.boxShown && !shelving);
  show(boxHigh, s.boxShown && shelving);
  if (s.boxShown && !shelving) boxLow.setAttribute("transform", translateAlong(P, [BOX_FROM_X * (1 - s.boxOn), BOX_ON_LIFT_Y, s.lift + (s.boxOn < 1 ? BENCH_TOP + 1 - LOW : 0) * (1 - s.boxOn)]));
  if (shelving) boxHigh.setAttribute("transform", translateAlong(P, [BOX_TO_X * s.boxShelved, BOX_ON_LIFT_Y * (1 - s.boxShelved), COUNTER_TOP + 0.8 * s.boxShelved]));

  const text = s.phase + " · " + clock(Math.min(t, RUN.finishedAt));
  if (readout.textContent !== text) readout.textContent = text;
  stage.setAttribute("aria-valuenow", String(Math.round(t)));
  stage.setAttribute("aria-valuetext", text);
}

// The run is 87 seconds; the tour plays it eight times as fast and rests.
const SPEED = 8, REST = 2.4, END = RUN.finishedAt;
const MARKS = [0, RUN.queuedUntil, RUN.preparedAt, RUN.handedOverAt, STEPS_DONE, RUN.raisedAt, END];
let t = 0, target = 0, touring = true, visible = false, frame = 0, last = 0, idleTimer = 0, rest = 0;
function tick(now) {
  const dt = last ? Math.min((now - last) / 1000, 1 / 30) : 1 / 60;
  last = now;
  if (touring) {
    if (t >= END) { rest += dt; if (rest >= REST) { rest = 0; t = 0; } }
    else t = Math.min(END, t + dt * SPEED);
  } else {
    t = still.matches ? target : t + (target - t) * (1 - Math.exp(-dt / 0.22));
    if (Math.abs(target - t) < 0.02) t = target;
  }
  draw(t);
  const settled = !touring && t === target;
  frame = visible && !settled ? requestAnimationFrame(tick) : 0;
}
const run = () => { if (!frame && visible) { last = 0; frame = requestAnimationFrame(tick); } };
const steer = (next) => {
  touring = false;
  target = Math.min(END, Math.max(0, next));
  clearTimeout(idleTimer);
  idleTimer = setTimeout(() => { touring = !still.matches; rest = 0; run(); }, 4000);
  run();
};
new IntersectionObserver((entries) => { visible = entries[entries.length - 1].isIntersecting; if (visible) run(); }, { rootMargin: "120px 0px" }).observe(stage);
if (still.matches) { touring = false; t = target = END; }
stage.addEventListener("pointermove", (event) => {
  const box = svg.getBoundingClientRect();
  steer(END * Math.min(1, Math.max(0, ((event.clientX - box.left) / box.width - 0.12) / 0.76)));
});
stage.addEventListener("pointerleave", () => steer(target));
stage.addEventListener("keydown", (event) => {
  const here = MARKS.reduce((best, mark, index) => (Math.abs(mark - target) < Math.abs(MARKS[best] - target) ? index : best), 0);
  let to = null;
  if (event.key === "ArrowRight" || event.key === "ArrowUp") to = Math.min(MARKS.length - 1, here + 1);
  if (event.key === "ArrowLeft" || event.key === "ArrowDown") to = Math.max(0, here - 1);
  if (event.key === "Home") to = 0;
  if (event.key === "End") to = MARKS.length - 1;
  if (to === null) return;
  event.preventDefault();
  steer(MARKS[to]);
});
draw(t);
`;

const body = k.plateHtml({
  fig: 'Fig 1',
  title: 'The pass',
  hint: 'Hover to move through the run',
  readout: `${first.phase} · 0:00`,
  keys: [
    {
      mark: 'lit',
      label: 'What travels: a ticket down, the finished work back',
    },
    {
      mark: 'raised',
      label: 'Counter: the Worker. Bench: GitHub Actions, one lamp a step',
    },
  ],
  caption:
    'A template run on the Cloudflare deployment. The Worker cannot run a template itself, so it sends the request down to GitHub Actions and waits. Most of the 1 minute 27 seconds of this real run is the lift going down: the runner being prepared. The four steps take seconds, and the result is back on the shelf as soon as the last one finishes.',
  body: `<div class="iso-stage" tabindex="0" role="slider" aria-label="A template run: arrow keys move between its stages" aria-valuemin="0" aria-valuemax="${RUN.finishedAt}" aria-valuenow="0">${svg}</div>`,
});

// The page loads its scripts from files beside it, so it also works where a
// content security policy forbids inline scripts, as the Node backend's does.
// One page serves both themes: a first, blocking script takes the reader's
// preference before anything is painted.
const flag = name => {
  const index = process.argv.indexOf(name);
  return index < 0 ? undefined : process.argv[index + 1];
};
const OUT =
  flag('--out') ??
  join(HERE, '..', '..', '..', 'packages', 'app', 'public', 'figures');
const forced = flag('--theme');
const page = k
  .pageHtml({ title: 'The pass: a template run', theme: 'dark', body })
  .replace(
    '<body class="iso" data-theme="dark">',
    '<body class="iso" data-theme="dark"><script src="the-pass.theme.js"></script>',
  )
  .replace(
    '</body>',
    '<script type="module" src="the-pass.js"></script></body>',
  );
mkdirSync(OUT, { recursive: true });
writeFileSync(join(OUT, 'the-pass.html'), page);
writeFileSync(
  join(OUT, 'the-pass.theme.js'),
  forced
    ? `document.body.dataset.theme = ${JSON.stringify(forced)};\n`
    : 'document.body.dataset.theme = matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";\n',
);
writeFileSync(join(OUT, 'the-pass.js'), kitScript() + live);
console.log('wrote', join(OUT, 'the-pass.html'));
