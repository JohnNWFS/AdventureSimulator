# Animation Engine Prototype Plan

This document proposes a low-risk path from the current text-first simulation to a first-pass visual playback system.

## Guiding idea

Use **deterministic beat logs** as the single source of truth, and layer visuals on top in increasing fidelity:

1. **Blockout phase**: rectangles/circles + simple camera zones + text cards.
2. **Line-art phase**: static background plates (hand-drawn or generated) + placeholder sprites.
3. **Production phase**: polished sprites/VFX/audio replacing placeholders without changing timing logic.

Because the simulator is deterministic, this lets us iterate on pacing and readability before art lock.

## Recommended architecture

## 1) Keep simulation and rendering separate
- Simulation emits beat events/tags.
- Animation engine consumes a normalized timeline of those events.
- No gameplay logic should depend on visual assets.

## 2) Add an intermediate "shot script"
Define a script format generated from beat tags. Each shot should include:
- `beat_tag`
- `anim_id` (existing mapping)
- `duration_ms`
- `background_id`
- `actor_blocks` (placeholder rectangles with position/size/color)
- `text_overlay`
- `transition_in` / `transition_out`

This script becomes the editable pacing layer between simulation and final animation.

## 3) Treat backgrounds as interchangeable assets
Support both:
- **Line drawing plates** (manual sketches), and
- **AI-generated concept plates** (e.g., DALL·E),

using the same `background_id` contract so we can swap assets without changing logic.

## Suggested iteration loop

1. Run seeded simulation.
2. Convert beats to shot script.
3. Preview with primitive blocks only.
4. Adjust durations, staging, and transitions.
5. Replace selected blocks with temporary sprites.
6. Repeat with same seed to compare before/after.

## Placeholder conventions (for speed)

- Party members: colored rectangles by role.
- Enemies: outlined squares/diamonds by threat tier.
- Interactables (chest/merchant/door): solid icon blocks.
- Damage/heal: simple floating bars and color flashes.
- Camera: fixed lanes (`scene`, `overlay`, `ui`) aligned to existing beat mapping.

## Practical first milestone (1-2 days)

- Build a tiny playback object that:
  - reads current beat tag,
  - resolves it through `sim_beat_animation_map_get`,
  - instantiates a default shot template,
  - plays a timed placeholder animation.
- Ship with 5-8 high-frequency beats first:
  - `ADVENTURE_START`, `ENCOUNTER`, `COMBAT_EXCHANGE`, `LOOT_FOUND`, `CITY_ARRIVE`.

## Risks and mitigations

- **Risk**: Overfitting animations to current log wording.
  - **Mitigation**: bind to beat tags/fields, not freeform text.
- **Risk**: Art generation churn.
  - **Mitigation**: freeze framing/timing in placeholders before detailed asset production.
- **Risk**: Debug difficulty.
  - **Mitigation**: on-screen display of active `beat_tag`, `anim_id`, and timeline cursor.

## Immediate next actions

1. Define shot script struct schema in GML comments/docs.
2. Implement minimal beat->shot adapter for the first 5-8 beats.
3. Add a toggle in the sim room to switch between text-only and blockout playback.
4. Capture short seed replays to compare pacing after each adjustment.
