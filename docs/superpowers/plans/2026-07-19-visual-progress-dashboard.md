# Visual Progress Dashboard Implementation Plan

**Status:** FAIL / BLOCKED ON CLAUDE RE-REVIEW

**Goal:** Build the approved fixture-only, original mountain-pass progress
dashboard as an optional top-level `dashboard/` companion.

**Architecture:** Dependency-free HTML, CSS, inline SVG, and vanilla ES modules.
One immutable fixture adapter boundary feeds normalized snapshots to a DOM-only
renderer. Deterministic map allocation and accessible text are pure/testable.

**Authoritative design:**
`docs/superpowers/specs/2026-07-19-visual-progress-dashboard-design.md`

## Ownership and gate

- [x] `deep-researcher`: repository/reference/integration research, read-only.
- [x] `lead-architect`: approve visual/data architecture and protected scope.
- [x] `workflow-coordinator`: discover durable paths and Notion applicability.
- [x] `lead-architect`: persist approved artifacts after two coordinator write
  invocations stalled without filesystem output; this exception is recorded.
- [x] User: submit the initial QA prompt, design, and source packet in Claude
  Chat and return the complete verdict.
- [x] `lead-architect`: record the FAIL and disposition all three blockers.
- [ ] User: submit the updated design, source packet, and focused re-review
  prompt in Claude Chat and return the complete verdict.
- [ ] `lead-architect`: approve a re-review PASS.
- [ ] `builder`: implement only after the gate passes.
- [ ] `workflow-coordinator`: record verification, residual risk, adapter seam,
  and next owner.

No relevant Notion task/page was discovered. Do not create or update Notion.

## Protected boundaries

- Create runtime code only under `dashboard/`.
- Do not modify README, installers, terminal startup, `tmux/`, `wezterm/`,
  wallpapers, LLM status/daemon, CI, or existing user changes.
- Fixtures only; no live terminal/process data, commands, polling, timers used as
  polling, control, network APIs/services, persistence, auth, analytics, or
  remote logging.
- No package manifest, dependency, framework, backend, copied reference code,
  branded assets, or protected track/car treatment.

## Task 1: QA-planning gate (`lead-architect` + user)

- [x] Create focused source packet.
- [x] Create self-contained Claude QA-planning prompt.
- [x] Supply both files and the approved design to Claude Chat.
- [x] Record FAIL with three blockers: route capacity terminology, invalid
  progress policy, and missing contrast verification.
- [x] Resolve B1 with a shared 16-slot route pool, four slots per named segment,
  six bays per stationary zone, a stated 24-session envelope, and exact tests.
- [x] Resolve B2 by rejecting every present non-number, non-finite, or
  out-of-range progress value while hashing only missing progress.
- [x] Resolve B3 with dependency-free WCAG contrast-token tests and a named
  manual contrast audit.
- [x] Accept the seven non-blocking recommendations as focused tests/clarity.
- [x] Create focused Claude re-review prompt.
- [ ] Obtain re-review PASS and explicit `Builder may begin` authorization.

Builder must not start Task 2 while any Task 1 box after artifact creation is
unchecked.

## Task 2: Contract, fixtures, and deterministic layout (`builder`)

**Create:**
`dashboard/src/session-contract.mjs`, `dashboard/src/fixture-adapter.mjs`,
`dashboard/src/fixture-sessions.mjs`, `dashboard/src/track-layout.mjs`, and
`dashboard/tests/dashboard.test.mjs`.

- [ ] Implement the exact six-state and permission enums and snapshot contract.
- [ ] Validate required fields, duplicate IDs, error/waiting invariants, and
  timestamps; reject present progress unless it is finite and within 0..1.
- [ ] Build deterministic labels and activity ages from snapshot `generatedAt`.
- [ ] Define the 16-slot shared route pool, four slots per named segment, six
  bays per stationary zone, FNV-1a-32 fallback, forward probing, and overflow.
- [ ] Add the fixed canonical fixture: 6 active, 6 thinking, and 3 per parked
  state.
- [ ] Test all mappings/invariants; malformed timestamps/progress; exact
  capacity arithmetic; collision/reorder behavior; N+1 overflow with complete
  rail detail; 24 unique anchors; and long-name preservation.

## Task 3: Full-screen visual and interaction (`builder`)

**Create:** `dashboard/index.html`, `dashboard/styles.css`,
`dashboard/src/app.mjs`, and `dashboard/src/render-dashboard.mjs`.

- [ ] Draw the original four-segment SVG route and four stationary zones.
- [ ] Render native car buttons at deterministic anchors with state-specific
  text, glyph/pattern/silhouette, tooltip, rail counterpart, and visible focus.
- [ ] Implement tooltip pin/highlight with Enter/Space and clear with Escape.
- [ ] Keep the rail compact and semantic; add a skip link and no duplicate rail
  tab stops.
- [ ] Implement desktop/mobile layouts, 44px controls, wrapping names, bounded
  rail scrolling, and no horizontal overflow.
- [ ] Animate only active/thinking nested bodies and fully disable optional
  motion/transitions under reduced motion.
- [ ] Render invalid snapshots and capacity overflow visibly.

## Task 4: Local handoff and focused verification (`builder`)

**Create:** `dashboard/README.md` and optionally retained evidence under
`dashboard/tests/screenshots/`.

- [ ] Document an independent loopback-only local preview command and unit test
  commands; state that no terminal integration occurs.
- [ ] Run `node --check` on every `.mjs` file.
- [ ] Run `node --test dashboard/tests/*.test.mjs`.
- [ ] Record build/lint/type checks as N/A where no toolchain exists.
- [ ] Run browser checks at 1440x900 and 390x844, normal and reduced motion.
- [ ] Assert nonblank framing, all car/rail equivalents, unique in-map bounds,
  no clipping/overflow, long-name behavior, and animation policy.
- [ ] Test CSS color tokens with WCAG luminance math: 4.5:1 text/glyph and 3:1
  focus/non-text boundaries.
- [ ] Manually audit contrast at both viewports across normal, hover, focus,
  selected, error, and overflow states; sanity-check the longest accessible text
  with VoiceOver.
- [ ] Capture desktop and mobile screenshots.
- [ ] Run the repository's existing shell syntax/ShellCheck, script, Lua, and
  Neovim checks.

## Task 5: Boundary audit and coordination closeout

- [ ] Confirm the diff contains no `fetch`, `XMLHttpRequest`, `WebSocket`,
  `EventSource`, `sendBeacon`, analytics, `child_process`, tmux/WezTerm imports,
  process polling, `setInterval`, dependency, package, daemon, or remote service.
- [ ] Confirm no protected existing file changed and unrelated dirty work is
  preserved.
- [ ] Confirm no reference coordinates, timings, asset names, or external asset
  URLs were carried into the implementation.
- [ ] `lead-architect` reviews implementation against this plan.
- [ ] `workflow-coordinator` records exact commands/results, screenshot paths,
  remaining manual-only risks, future read-only adapter seam, and next owner.

## Current evidence and exceptions

- Discovery found no existing web stack or relevant Notion task.
- Public reference review used primary GitHub sources and established a strict
  no-copy/no-brand boundary.
- Worktree already contains modified README/installers/anime manifest and an
  untracked `codex/` tree; they belong to the user.
- Hyphenated native agent names are unsupported by the orchestration API.
- Runtime model/reasoning pins were not exposed or confirmed; no substitution
  is claimed.
- Claude CLI is unavailable on the user's free plan, so the user is next owner
  for manual Claude Chat QA planning.

## Required final confirmations

- [ ] The dashboard is optional, self-contained, independently removable, and
  does not change default WezTerm/tmux behavior.
- [ ] Live tmux/WezTerm integration is deferred.
