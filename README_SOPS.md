# GPT CODING / GITHUB SOP — TICK SURVIVAL LAB

> **MANDATORY ENTRY CONDITION FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread this file and `README_CONTEXT.md` from current `main`, then inspect the current repository state relevant to that prompt. Refresh once per prompt/change request, not before every individual edit.

## 1. Core operating rules

1. **Current repo beats memory.** Fetch first.
2. **Canonical Godot source is `game/`.**
3. **Direct `main` is normal** unless the user explicitly requests a branch/PR workflow.
4. **Batch coherent changes.** One prompt should normally produce one coherent implementation pass.
5. **One durable owner per rule.** Do not duplicate simulation logic across UI, map, actor, or persistence modules.
6. **Small blast radius beats cleverness.** Refactor locally when the feature requires it; do not conduct project-wide rewrites without explicit authorization.
7. **No First Fire creep.** Do not import camp/menu/expedition code merely because it is nearby in the source project.
8. **No clone-by-copying.** Project Zomboid is a design reference, not a source of code/assets/content.
9. **Do not claim a build works without actually running the relevant Godot parse/startup checks.**
10. **Keep the simulation testable without presentation.** Tick/world rules should not require UI nodes to function.

## 2. Required pre-code checklist — once per prompt

Before changing code or repository behavior:

1. Fetch/read `README_SOPS.md`.
2. Fetch/read `README_CONTEXT.md`.
3. Fetch current `main` SHA.
4. Inspect the actual `game/` files relevant to the requested change.
5. Identify the permanent subsystem owner and smallest integration surface.
6. Check whether the change alters persistent world/save shape.
7. Check whether the change changes tick semantics or ordering.
8. Fetch current blob SHAs for files that will be replaced through GitHub's Contents API.
9. Choose the write path before producing large replacements.

Do not repeat this checklist between edits inside the same prompt unless another actor changes `main` in a way that affects the work.

## 3. Bootstrap architecture

Current durable owner:

- `TacticalMapGenerator.gd` — authored physical map catalog, map variants, structural map specification, map selection, and map validation.

Current disposable harness:

- `MapPreview.gd` — renders/rerolls maps so the extracted foundation can be tested. It owns no future gameplay rule.

Preferred dependency direction:

**map/data → persistent world state → tick scheduler/rules → actor simulation → presentation/input**

When a new rule becomes real, give it one clear owner. Do not put inventory, combat, infected AI, needs, saving, or tick scheduling into `TacticalMapGenerator.gd`.

## 4. Tick-authority rules

The world tick will become the authoritative simulation time.

When implemented:

- every meaningful action has an explicit tick cost;
- player and infected actions use the same scheduler model;
- world timers are expressed against authoritative ticks rather than UI animation duration;
- rendering interpolation must never silently change simulation outcomes;
- pausing/input inspection must not advance world time unless an action commits;
- deterministic ordering rules must be documented and regression-tested.

Do not mix real-time `_process(delta)` timing into authoritative simulation because it is convenient for one feature.

## 5. Map rules

The current map system is **authored-layout + randomized selection**, not infinite procedural generation.

Preserve one map schema while expanding it. If connected-world generation arrives later, compose/stitch/transform this schema rather than creating a second incompatible physical-world model.

Map geometry/data may describe physical facts such as ground, walls, doors, windows, obstacles, props, lights, spawn anchors, and exits. Runtime state such as a broken window, opened door, corpse, dropped item, blood, fire, or actor belongs to persistent world state unless the generator specifically owns its initial placement.

## 6. GDScript rules

- Godot 4 / GDScript.
- Be conservative with `:=` when values come from Dictionaries/Variants; use explicit types/conversions when inference is ambiguous.
- Prefer `maxi`, `maxf`, `clampi`, `clampf` when appropriate.
- Treat Dictionary schemas, signal names, method names, and save keys as APIs.
- Keep `_ready()` side effects small and understandable.
- Prefer deterministic helper tests for map/tick invariants.
- Do not hide simulation mutation inside draw/input helpers.

## 7. Persistence policy

Persistent-world design is core, but no save format is sacred during bootstrap.

Before a public Beta promise exists:

- change schemas when necessary rather than carrying dead compatibility fields;
- keep explicit schema/version metadata once saves are introduced;
- do not build a general migration framework until there is an actual compatibility promise.

## 8. GitHub write path

For modest text changes, prefer `fetch_file` + `create_file` / `update_file` / `delete_file`.

For coordinated multi-file changes, prefer Git Data blobs/tree/commit with one fast-forward of `main` when available.

Temporary Actions writers are emergency fallback only. If one is ever required, remove it immediately after use and verify the final tree contains no migration/staging junk.

## 9. Validation

At minimum for meaningful GDScript work:

1. Godot import/parse succeeds.
2. The actual main scene starts headlessly without script/load errors.
3. Deterministic module smoke tests pass when they exist.
4. Logs are rejected if they contain `SCRIPT ERROR`, `Parse Error`, or `Failed to load script`.

Permanent Pages CI is present from Bootstrap 0.0 and must remain the default proof path. A code change is CI-good only when the exact final SHA passes canonical validation, Godot import/parse, `MapSmoke.gd`, startup smoke, Web export, artifact upload, and Pages deployment. Inspect logs for meaningful GDScript changes.

Current map bootstrap invariant: every catalog environment/variant must pass `TacticalMapGenerator.validate_layout()`.

## 10. Scope discipline

Do not start by reproducing an entire mature survival game.

Current first-slice priorities are the local physical simulation: one player, ticks, movement/facing, environment interaction, vision, sound, infected, loot/inventory, body state, and persistent local world changes.

Multiplayer, vehicles, NPC companions, factions, settlement management, giant crafting trees, and elaborate narrative systems are outside the bootstrap unless the user explicitly changes scope.

## 11. Communication

- Implementation-first, not process-first.
- Keep progress updates short and useful.
- Surface discovered architectural facts early—for example, the current First Fire “generator” is authored map variants, not an infinite procedural city generator.
- Avoid unnecessary clarification when repo/context resolves the question.
- If a required external mutation is impossible with available tooling, say exactly what is blocked and complete everything that can be completed safely.
- Never claim a GitHub repo, CI run, build, or deployment exists unless verified.

## 12. Final self-check

Before saying a code/repo prompt is done:

- Did I refresh SOP + context once at prompt start?
- Did I inspect current relevant source?
- Did I preserve the map module boundary?
- Did I avoid importing unrelated First Fire systems?
- Did I account for tick/persistence implications?
- Did I run relevant validation?
- Did I leave no temporary artifacts?
- Did I report any tooling blocker accurately?

## 13. Required footer after repository changes

When a prompt changes this repository, end the completion response with:

- Changelog: `https://github.com/dmcexcess-lab/dmcexcess-lab-tick-survival-lab/blob/main/CHANGELOG.md`
- Play: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
