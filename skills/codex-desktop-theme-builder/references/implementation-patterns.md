# Implementation patterns

Use these patterns only after inspecting the target Codex version. Treat all selectors as hypotheses until verified in the live DOM.

## Runtime architecture

Keep the theme outside the signed installation:

1. Resolve the current Codex executable at runtime.
2. Start it with a dedicated `--user-data-dir` and an available remote-debugging port.
3. Start a small injector process that discovers non-pet `app://-/index.html` targets.
4. inject CSS and a bootstrap function through the debugging protocol.
5. Store PID, port, version, and profile path in the isolated profile for idempotent stop/restart.

Never copy user cookies, preferences, or credentials into the theme repository.

## Idempotent ownership

Give every owned global node a stable ID. On every pass:

- update the existing style node instead of appending another;
- reuse a decorative SVG only when it belongs to the current main surface;
- remove owned nodes when entering home or a skipped route;
- replace an old observer rather than registering duplicates;
- expose a small version/state object for diagnostics.

Do not remove native nodes during cleanup.

## State detection

Use native controls, not conversation text.

| State | Strong signal | Fallback | Visual behavior |
|---|---|---|---|
| Home | Home cards/composer combination and no conversation ID | Verified route structure | Character background; no chat signal map |
| Running | Enabled primary action represents stop/cancel | Stable stop-icon path scoped to the primary action | Moving edge signals, restrained central motion, `LIVE` marker |
| Complete | Conversation exists and primary action is send | Absence of the narrow running signal | Frozen paths, static seal, `SEALED` marker |
| Pet overlay | `initialRoute=avatar-overlay` or verified pet target URL | None | Remove theme ownership and return |

When React reuses the primary button, observe only relevant `aria-label`, `disabled`, and icon-path attributes. Debounce application and never observe theme-owned attributes.

## Selector strategy

Prefer, in order:

1. stable `data-*` attributes that describe product intent;
2. ARIA roles and states scoped to a verified component;
3. persistent structural relationships;
4. generated classes only as a last, version-specific fallback.

Avoid relying on Chinese or English labels for core behavior. Localized text is acceptable only in diagnostics that have a structural fallback.

## Canvas and motion layers

Keep content above decoration. A robust stack is:

1. state color field;
2. static texture or star field;
3. non-interactive SVG routes/nodes;
4. native viewport and messages;
5. composer and native overlays.

For reading-heavy layouts, split animation spatially:

- preserve richer/faster motion on outer edges;
- mask the central content band and give it fewer, dimmer, slower pulses;
- leave base routes static so the visual metaphor remains when motion is disabled.

Use deterministic generation for large star fields or particles. Keep node counts modest, reuse the SVG, and avoid rebuilding it on every mutation.

## Menu overflow fixes

Inspect the exact scroll container and its descendants. If a model list exposes both axes:

- set `overflow-x: hidden` only on the verified model menu and its vertical fade mask;
- retain `overflow-y: auto`;
- hide only the horizontal WebKit scrollbar track;
- verify that reasoning/speed sliders and keyboard navigation still work.

Do not apply a global `overflow: hidden` to menus or popovers.

## Reduced motion

Disable all repeated animation in one media rule, including pseudo-elements and SVG descendants. Keep borders, static color fields, stars, frozen routes, and state labels visible so task state remains recognizable without motion.

## Pet isolation

Run the overlay check before creating the style node. Cleanup must remove:

- theme style and decorative DOM nodes;
- root theme/home/task classes and data attributes;
- composer task attributes owned by the theme.

Do not set page backgrounds, minimum dimensions, or layout rules in the pet target.
