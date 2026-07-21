# Claude QA-Planning Handoff: Visual Progress Dashboard

## Role

You are the independent lead QA architect for a pre-implementation visual web
dashboard. Be adversarial, evidence-based, accessibility-aware, and strict about
scope isolation and intellectual-property boundaries.

## Stage

Pre-implementation QA-planning gate. No implementation diff exists. Your verdict
decides whether the Builder may begin.

## Scope

Review the proposed architecture, data/state contract, deterministic placement,
accessible interaction/text model, responsive behavior, animation and reduced-
motion policy, fixture strategy, capacity behavior, IP boundary, adapter seam,
and verification plan for completeness and testability.

Read the full contents supplied with this chat:

1. `docs/superpowers/specs/2026-07-19-visual-progress-dashboard-design.md`
2. `docs/superpowers/qa/2026-07-19-visual-progress-dashboard-source-packet.md`
3. This prompt.

## Context

The target is a terminal-dotfiles repository with no existing web stack. The
dashboard is an optional, independently runnable/removable top-level
`dashboard/` companion. It is a fixture-only, full-screen visual progress
surface where small cars occupy an original nighttime mountain route or named
stationary zones. It is not a terminal, chat client, session manager, or live
integration.

The proposed stack is dependency-free semantic HTML, CSS, original inline SVG,
vanilla ES modules, and Node built-in tests. A fixture adapter returns one
schema-v1 immutable snapshot. Pure normalization/layout code maps six states to
deterministic anchors and accessible labels. Browser checks use locally
available tooling without adding a repository dependency.

## Acceptance criteria

- Every session's state and relative position are identifiable without opening
  a card or reading chat.
- Multiple route and pit sessions have distinct, unambiguous anchors/labels.
- Every fixture state maps to correct car treatment, route/pit placement, and
  accessible text.
- Desktop/mobile layouts handle long names and a verified 24-session mixed set.
- Capacity overflow is explicit and never silently overlaps.
- Motion is subtle and deterministic enough to test; reduced motion disables it.
- Keyboard access, focus visibility, semantic labels, non-color encoding,
  contrast, and touch target sizes are preserved.
- The adapter seam is deliberate but performs no live integration.
- Unit and browser checks target the highest-risk mapping, accessibility,
  motion, capacity, and responsive failures.
- Desktop/mobile screenshots are nonblank, correctly framed, and free of
  overlap/clipping.

## Protected boundaries

- Runtime implementation may add files only under `dashboard/`.
- Do not alter README, installers, startup, tmux, WezTerm, wallpaper workflows,
  existing daemon/LLM status, CI, or unrelated dirty work.
- No live tmux/WezTerm/process reads, polling, commands, callbacks, navigation,
  control, collector, watcher, or daemon.
- No network APIs/services, analytics, remote logging, persistence, auth, cloud,
  backend, package manifest, dependencies, framework, or design system.
- No Pokegents code/assets/layout/coordinates/algorithms/timings/iconography and
  no Pokémon/Initial D or other branded/copyrighted treatment.
- Absence of live integration is intentional, not a missing v1 feature.

## Relevant source contents or focused diff

There is no implementation diff. Use the supplied source packet as the focused
repository/reference evidence. Treat the approved design as the proposed public
contract. Do not require access to private links or assume unstated source.

Pay special attention to:

- malformed, contradictory, duplicate, missing, boundary, and over-capacity
  snapshot inputs;
- fail-open behavior that could silently mislabel or overlap a session;
- deterministic collision resolution under input reordering;
- whether progress clamping hides invalid data or has a clear policy;
- keyboard/tooltip semantics, duplicate focus targets, accessible names, and
  non-color encodings;
- mobile map scale, 44px targets, rail scrolling, long names, and overflow;
- normal/reduced-motion computed behavior and screenshot determinism;
- originality/IP leakage from the public reference;
- protected-file, process, polling, and network isolation;
- whether the proposed tests can actually prove the acceptance criteria without
  adding dependencies.

## Verification

Evaluate whether the planned Node tests and 1440x900/390x844 browser checks
provide named evidence for each acceptance criterion. Recommend the smallest
additional test for any real gap. Distinguish automated evidence, visual
screenshot review, and unavoidable manual checks. Do not invent build/lint/type
tooling for a zero-build implementation.

## Known non-goals

Live data collection; tmux/WezTerm control; chat/transcripts/prompts; session
cards; faux terminal; persistence; auth; telemetry; remote services; installer,
startup, status, wallpaper, README, or CI integration; unlimited capacity; and
copying a reference product or franchise are all deliberately out of scope.

## Output required

Return exactly these sections:

1. **Verdict:** `PASS` or `FAIL`.
2. **Implementation authorization:** explicitly `Builder may begin` or `Builder
   must not begin`.
3. **Blocking findings:** severity ordered; for each, cite the relevant design
   statement, explain the failure mode and acceptance criterion at risk, and
   give the minimal resolution. Say `None` if PASS.
4. **Non-blocking recommendations:** clearly separated from blockers and future
   work.
5. **Missing tests and edge cases:** map each addition to a risk/criterion and
   label automated, screenshot, or manual.
6. **Protected-boundary audit:** state whether isolation, no-live-integration,
   network/process, and IP boundaries are adequate.
7. **Explicit sign-off status:** one sentence suitable for pasting into the
   implementation plan.

Attack assumptions and distinguish genuine v1 blockers from optional future
hardening. A FAIL must identify a concrete minimal path to re-review.
