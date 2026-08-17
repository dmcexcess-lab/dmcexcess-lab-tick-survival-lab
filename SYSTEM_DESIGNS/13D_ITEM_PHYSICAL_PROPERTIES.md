# Tick Survival Lab — 13D Item Physical Properties

Status: **IMPLEMENTED + CI**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Own reusable physical item-definition facts needed by multiple mechanics, beginning with real item weight, without owning item location or carried totals.

## Owner
- `game/scripts/simulation/items/properties/ItemPhysicalProfile.gd`
- `game/scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd`
- `game/scripts/simulation/items/properties/ItemWeightQuery.gd`
- smoke: `game/scripts/ci/ItemPhysicalPropertiesSmoke.gd`

## Contract
V1 physical profiles are explicit semantic `item.*` type definitions containing positive integer **weight in grams**. Integer grams avoid floating drift and have a clean display conversion (`1000 g = 1 kg`).

The catalog deliberately ships with no guessed universal weights. Content/demo composition explicitly registers the semantic item types it actually creates. Profile reads are copy-safe and deterministic.

`ItemWeightQuery` maps a stable WHAT item ID through its semantic type to a profile and returns typed KNOWN / UNKNOWN / INVALID status. Missing profile is UNKNOWN/fail-closed, never implicit zero. Non-item WHAT identity is INVALID.

V1 weight is semantic-type data, not redundant per-instance state. A future true per-instance physical modifier requires its own typed design rather than a generic metadata bag.

## Persistence / boundaries
The catalog is content/configuration, not per-save actor state, so it has no actor snapshot. WHAT/09/11/12 remain the owners of item identity/location/disposition.

Allowed dependency: read-only WHAT in `ItemWeightQuery`.
Forbidden: 09 Hands, 11 Inventory, 12 Transfer, Carry mutation, Health, Needs, Skills, UI/render/art, reboot.

## Verification
`ItemPhysicalPropertiesSmoke.gd` proves the catalog starts empty, positive integer gram registration, deterministic type ordering, duplicate/invalid rejection, copy safety, WHAT resolution, missing-profile UNKNOWN, non-item INVALID, and missing-item UNKNOWN.

Initial complete System 13 candidate `78ed167678257749b093acd54e53e9f065cd8ce5` passed **Actor Stats Domains contract** run `31992365565` with no production repair.

## Approved decisions — 2026-08-16
1. Weight is canonical integer grams.
2. Weight is registered by semantic item type in v1.
3. Missing weight classification is UNKNOWN, never implicit zero.
4. The catalog contains no guessed built-in weights merely to populate UI.
5. 13D never owns item disposition or carried totals.
