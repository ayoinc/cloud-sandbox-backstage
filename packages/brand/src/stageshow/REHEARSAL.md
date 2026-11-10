# Rehearsal: CatalogSearchDemo

Gold: `fade-crop` (Stageshow skill). Kept: one gutter above and to the left of
the window, the window running off the right edge, a mask that fades only the
foot, real content in the top half and placeholder under the fade. Changed: the
still became a loop; the browser window became a sidebar window in the portal's
own colours; the stage is not a fixed size but is fitted to the sign-in page's
brand panel (the panel is the ground, so there is no plate behind the window).
The search mechanics were read from `wikipedia` and the sidebar window from
`linear`.

Beats: 1 click the catalog filter (0.7s) … 2 type "kafka", eleven rows leave,
Apache Kafka closes up under the header and the next section comes up (2.4s) …
3 open Apache Kafka (3.9s) … 4 its page arrives and the three relations draw
(4.8s) … payoff holds 2.6s (6.2s) … reset: click Components in the sidebar, a
fresh catalog (8.8s). Loop 10.3s.

Captured: the playground harness at the shown size (panel 533, slot 485x417,
stage 1:1, Lato loaded), light and dark: the loop at 600/650/700ms, `--states`,
the narrowing at 50ms, the click and both page changes at 30 to 40ms, reduced
motion. Other panel sizes as payoff stills (420 and 800 wide, a 270px slot).
The built sign-in page at 1280x800 light and dark, 390x844, and 1280x800 with
reduced motion.

Gate: `rehearsal passed (necessary, not sufficient: references/verify.md and the fresh eye in review.md still stand)`
on the loop (light at three sampling intervals, dark) and on `--states` (light
and dark), in the playground at the shown size.

Film: each line the last runs print, and why it stands.

- `dark slab: aside.ss-window__side is a near-black box inside the light
div.ss-window` → every light frame → stands. The portal's sidebar is the
  brand's dark teal in both themes; it is the product's identity, not a log
  panel. Both reviews judged it from the frame and agreed.
- `jump: ss-field__chars "k" width +6.6px in one frame` → the typing → stands.
  Typing is instant in the real thing; this is the kit `Field`'s own text, and
  the `linear` gold prints the same line.
- `vanishes with no exit: span.ss-swap__in "Catalog"` / `"Apache Kafka"` → the
  title at each page change → stands. It is the kit `Swap` handing the old
  words to its fading copy; the `payout-flow` gold prints the same line, and
  the second review filmed it as a blur-out and blur-in, not a pop.
- On the built page only, six `kit override: .ss-row …` lines fail the gate.
  They are the kit's own `parts/Row.css` rules: film tells kit CSS from scene
  CSS by a `/kit/` stylesheet URL, and the production bundle puts both in one
  chunk. The scene's CSS has no `.ss-row` selector. Every other line on the
  built page matches the playground.

Fixed on the way: a tight label/value stack and a bar past its card's padding;
the pointer resting on a clickable row; a portrait window crop on a narrow
panel; graph labels cut mid-word on a narrow panel; a blank pane between the
two pages (`empty pane`, which the `wikipedia` gold's own page change also
prints under `--states`), replaced by a dip: the page dims, is swapped at that
level and comes back up; placeholder lines of the two pages landing on each
other at the swap (`handoff shift`), so the two pages now end in different
lists.

Review: two fresh-eye passes.

First pass → response:

1. Sidebar a quarter of the slot, graph's second hop cut → sidebar 132 to 120;
   the graph is one hop and whole inside the crop.
2. Window's lower left dissolves into the panel → placeholder nav rows trail
   off towards the foot; the sidebar colour stays (it is the panel's token).
3. Bars where the eye lands in the catalog → stands: the brief limits real
   words to the story's own.
4. Narrowing not legible → the table now shortens to the one match and the
   section under it comes up.
5. Payoff's heaviest mark on a bar → the graph's root and two neighbours carry
   the names the card above already shows (no new strings).
6. Page change a double exposure → the dip described above.
7. Title read "Apache Kafk" while its box widened → the title's box is one
   fixed width.
8. Relations drew out of order → one hop, staggered from the entity, starting
   as the page lands.
9. Pointer parked on the graph → it rests in the title bar.
10. Click landed on a placeholder bar → the fingertip lands just past the name;
    the row answers with a hover fill.
11. Return path crossed the name and flashed a hand → the rest point is above
    the row.
12. Dark focus ring heavier than light → a 22% wash of the accent in dark mode.
13. Empty search field → stands: a placeholder word is outside the brief's
    word budget.

Second pass (it found the composition answers this product and page, and the
payoff's focal share equal to or better than the gold's) → response:

1. Last card finished inside the fade → both pages' last sections now run past
   the foot at every size.
2. Window stopped short of the slot on wide and narrow panels → the window may
   show up to 520px of its height (was 440) and be nearly square on a narrow
   panel (was 0.9); it stays capped there because a window taller than it is
   wide is a framing fault.
3. Anonymous surviving rows unreadable as matches → one match only.
4. More filler than nav in the sidebar → six placeholder rows that fade out.
5. Clicks showed no press → the kit's click ripple is on, and the row and the
   nav item have a pressed fill.
6. Narrowing showed a hole → stagger tightened to 30ms; the rest is the kit
   `Collapse` dimming a row before its space closes. `solid` was tried and left
   slivers of the closed rows, so it was not kept.
7. Hand beside its targets → stands for the row (the skill's rule: the cursor
   never covers the words it clicks); the Components click moved clear of the
   last letter.
8. Active-nav bar on the window's left edge in a colour used nowhere else →
   stands: it is the portal's own indicator token and position.

Assumptions:

- The demo sits between the lead copy and the "Built and run by" line, so on
  wide screens the copy now sits under the logo instead of floating mid-panel.
- A section card under the catalog table is placeholder invented so the page
  stays full when the table shortens; the real catalog page ends at its table.
- The window keeps macOS traffic lights (kit chrome) although the portal is a
  web app, as the `linear` gold does.

Unresolved:

- The sidebar and the brand panel are the same colour, so the window's left
  side is separated only by its hairline and shadow.
- Between 960px (the `md` breakpoint) and about 1000px viewport width the
  panel is too narrow to keep the story's words whole at a readable size, so
  no demo is shown there.
- On very wide panels the window is capped at 1.25x and 520px of height; the
  cards have empty space on their right and the panel is empty under it.

Not checked:

- No third review after the second pass's fixes; those changes were checked
  with the gate and the builder's own frames only.
- Safari and Firefox (filmed in Chrome only).
- Real-time feel on a slow device; every film run reports sampling gaps over
  27ms caused by its own screenshots.
- Windows high-contrast / forced-colors mode.
