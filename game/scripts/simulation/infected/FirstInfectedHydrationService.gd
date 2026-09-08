extends RefCounted
class_name FirstInfectedHydrationService

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

const HUMAN_SEMANTIC: StringName = &"actor.survivor"
const SEARCH_RADIUS: int = 12
const INVALID_CELL: Vector2i = Vector2i(-999999, -999999)

var _world: WorldState
var _mutations: WorldMutationService
var _spatial: SpatialQueryService
var _kernel: TickKernel
var _projection: PopulationResidentProjection
var _infected: InfectedState
var _locomotion: ActorLocomotionMutationService
var _hands: ActorHandEquipmentMutationService
var _inventory: InventoryContainmentMutationService
var _health: ActorHealthState
var _skills: ActorSkillState
var _carry: ActorCarryState
var _condition: ActorConditionState

func _init(world=null, mutations=null, spatial=null, kernel=null, projection=null, infected=null, locomotion=null, hands=null, inventory=null, health=null, skills=null, carry=null, condition=null) -> void:
    _world=world; _mutations=mutations; _spatial=spatial; _kernel=kernel; _projection=projection; _infected=infected
    _locomotion=locomotion; _hands=hands; _inventory=inventory; _health=health; _skills=skills; _carry=carry; _condition=condition

func is_ready() -> bool:
    return _world != null and _mutations != null and _spatial != null and _kernel != null and _projection != null and _infected != null \
        and _locomotion != null and _locomotion.is_ready() and _hands != null and _hands.is_ready() \
        and _inventory != null and _inventory.is_ready() and _health != null and _health.is_ready() \
        and _skills != null and _carry != null \
        and _condition != null and _condition.is_ready()

func hydrate_first(population_plan: Dictionary, preferred_area_site_id: String, reference_cell: Vector2i) -> Dictionary:
    var cohort: Dictionary = hydrate_cohort(population_plan, preferred_area_site_id, reference_cell, 1)
    if not bool(cohort.get("ok", false)):
        return {"ok": false, "reason": String(cohort.get("reason", "first_infected_hydration_failed"))}
    var members: Array = cohort.get("members", [])
    return {"ok": false, "reason": "first_infected_missing"} if members.is_empty() else Dictionary(members[0]).duplicate(true)

func hydrate_cohort(population_plan: Dictionary, preferred_area_site_id: String, reference_cell: Vector2i, target_count: int) -> Dictionary:
    if not is_ready(): return {"ok": false, "reason": "hydrator_not_ready", "members": []}
    if target_count < 1: return {"ok": false, "reason": "invalid_target_count", "members": []}
    var candidates: Array[Dictionary] = _projection.infected_near(population_plan, preferred_area_site_id, reference_cell)
    if candidates.is_empty(): return {"ok": false, "reason": "no_infected_resident_record", "members": []}

    var members: Array[Dictionary] = []
    for record: Dictionary in candidates:
        if members.size() >= target_count: break
        var result: Dictionary = hydrate_record(record)
        if bool(result.get("ok", false)):
            members.append(result.duplicate(true))
            continue
        var reason := String(result.get("reason", "unknown"))
        if reason == "resident_home_not_materialized" or reason == "resident_identity_unavailable":
            continue
        return {"ok": false, "reason": reason, "members": members.duplicate(true)}

    if members.size() < target_count:
        return {
            "ok": false,
            "reason": "insufficient_materialized_infected_residents:%d/%d" % [members.size(), target_count],
            "members": members.duplicate(true),
        }
    return {"ok": true, "reason": "", "members": members.duplicate(true)}

func hydrate_record(record_value: Dictionary) -> Dictionary:
    if not is_ready(): return {"ok": false, "reason": "hydrator_not_ready"}
    var record: Dictionary = record_value.duplicate(true)
    var actor_id := String(record.get("resident_id", ""))
    if actor_id.is_empty() or not bool(record.get("infected", false)):
        return {"ok": false, "reason": "resident_record_invalid"}
    if _world.has_entity(actor_id):
        var existing: WorldPlacement = _world.placement(actor_id)
        if existing != null and _infected.is_infected(actor_id):
            return {
                "ok": true,
                "actor_id": actor_id,
                "resident_record": _infected.resident_record(actor_id),
                "cell": existing.anchor,
                "existing": true,
            }
        return {"ok": false, "reason": "resident_identity_unavailable"}

    var home_cell: Vector2i = record.get("home_cell", INVALID_CELL)
    var spawn_cell := _clear_cell_near(home_cell)
    if spawn_cell == INVALID_CELL: return {"ok": false, "reason": "resident_home_not_materialized"}

    if _mutations.create_entity(HUMAN_SEMANTIC, actor_id) != actor_id: return {"ok": false, "reason": "actor_create_failed"}
    if not _mutations.set_placement(actor_id, Layers.Channel.ACTOR, spawn_cell, Facing.Value.SOUTH, Footprint.single_cell()):
        _mutations.remove_entity(actor_id); return {"ok": false, "reason": "actor_place_failed"}
    if not _locomotion.enroll(actor_id): return _rollback(actor_id, "locomotion_enroll_failed")
    if not _hands.enroll_actor(actor_id): return _rollback(actor_id, "hands_enroll_failed")
    if not _inventory.enroll_container(actor_id): return _rollback(actor_id, "inventory_enroll_failed")
    if not _health.enroll_actor(actor_id): return _rollback(actor_id, "health_enroll_failed")
    if not _skills.enroll_actor(actor_id): return _rollback(actor_id, "skills_enroll_failed")
    if not _carry.enroll_actor(actor_id): return _rollback(actor_id, "carry_enroll_failed")
    if not _condition.enroll_actor(actor_id, _kernel.world_tick()): return _rollback(actor_id, "condition_enroll_failed")
    record["hydrated_cell"] = spawn_cell
    if not _infected.record_hydration(actor_id, record): return _rollback(actor_id, "infection_record_failed")
    return {"ok": true, "actor_id": actor_id, "resident_record": record.duplicate(true), "cell": spawn_cell, "existing": false}

func _clear_cell_near(origin: Vector2i) -> Vector2i:
    for radius in range(0, SEARCH_RADIUS + 1):
        for y in range(-radius, radius + 1):
            for x in range(-radius, radius + 1):
                if radius > 0 and absi(x) != radius and absi(y) != radius: continue
                var cell := origin + Vector2i(x, y)
                if _spatial.has_terrain(cell) and _spatial.query_cell(cell, "", true).is_clear(): return cell
    return INVALID_CELL

func _rollback(actor_id: String, reason: String) -> Dictionary:
    if _world.has_placement(actor_id): _mutations.unplace_entity(actor_id)
    if _world.has_entity(actor_id): _mutations.remove_entity(actor_id)
    return {"ok": false, "reason": reason}