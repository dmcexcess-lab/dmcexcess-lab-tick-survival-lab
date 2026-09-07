extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const Rules = preload("res://scripts/foundation/time/TickRules.gd")
const Firearms = preload("res://scripts/simulation/combat/FirearmActionService.gd")
const Profiles = preload("res://scripts/simulation/combat/FirearmProfileCatalog.gd")

const GUN := "item.prompt.firearm"
const OLD_MAG := "item.prompt.mag.old"
const NEW_MAG := "item.prompt.mag.new"
const OLD_ROUND := "item.prompt.round.old"
const ROUND_A := "item.prompt.round.a"
const ROUND_B := "item.prompt.round.b"
const KEEPSAKE := "item.prompt.target.keepsake"

var failures: Array[String] = []

func _initialize() -> void: call_deferred("run_smoke")

func run_smoke() -> void:
    var packed := load("res://main.tscn") as PackedScene
    expect(packed != null, "production main scene loads")
    if packed == null: return finish()
    var game := packed.instantiate(); root.add_child(game)
    await process_frame; await process_frame

    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var spatial: SpatialQueryService = game.get("_spatial_query")
    var kernel: TickKernel = game.get("_kernel")
    var health: ActorHealthState = game.get("_health_state")
    var hands: ActorHandEquipmentState = game.get("_hand_state")
    var hand_mutations: ActorHandEquipmentMutationService = game.get("_hand_mutations")
    var inventory: InventoryContainmentState = game.get("_inventory_state")
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations")
    var firearm_state: FirearmState = game.get("_firearm_state")
    var firearm_actions: FirearmActionService = game.get("_firearm_actions")
    var corpse_state: CorpseState = game.get("_corpse_state")
    var death: ActorDeathTransitionService = game.get("_death_transitions")
    var sound: SpatialSoundService = game.get("_spatial_sound")
    var infected: InfectedState = game.get("_infected_state")
    var projection: PopulationResidentProjection = game.get("_population_resident_projection")
    var first_infected: Dictionary = game.get("_first_infected_result")
    var condition_state: ActorConditionState = game.get("_condition_state")
    var locomotion_state: ActorLocomotionState = game.get("_locomotion_state")
    var carry_state: ActorCarryState = game.get("_carry_state")
    var skill_state: ActorSkillState = game.get("_skill_state")

    expect(firearm_state != null and firearm_state.is_ready() and firearm_actions != null and firearm_actions.is_ready(), "production firearm owners are ready")
    expect(corpse_state != null and death != null and death.is_ready(), "generic death/corpse owners are ready")
    expect(inventory.has_container(Fixture.PLAYER_ID), "player is a real inventory container")
    expect(infected != null and projection != null and bool(first_infected.get("ok", false)), "production first infected is hydrated")
    if not failures.is_empty(): game.queue_free(); return finish()

    var target := String(first_infected.get("actor_id", ""))
    var resident := infected.resident_record(target)
    var global_plan: GeneratedGlobalWorldPlan = Fixture.global_plan()
    var population_plan := {
        "ok": global_plan != null and global_plan.is_generated(),
        "settlements": [] if global_plan == null else global_plan.population_settlements.duplicate(true),
        "local_area_manifest": {} if global_plan == null else global_plan.local_area_manifest.duplicate(true),
    }
    var projected_central := projection.infected_records(population_plan, Fixture.CENTRAL_SITE_ID)
    expect(not target.is_empty() and infected.is_infected(target), "hydrated actor has infection state on the same human identity")
    expect(String(resident.get("resident_id", "")) == target and String(resident.get("area_site_id", "")) == Fixture.CENTRAL_SITE_ID, "infected identity preserves central household resident provenance")
    expect(_record_exists(projected_central, target), "hydrated infected is one of the deterministic resident slots already counted as infected")
    expect(world.has_entity(target) and world.entity(target).semantic_type == &"actor.survivor", "infection overlays the shared human actor semantic instead of creating a parallel zombie species")
    expect(world.has_placement(target) and world.placement(target).channel == Layers.Channel.ACTOR, "first infected has real ACTOR occupancy")
    expect(health.has_actor(target) and hands.has_actor(target) and inventory.has_container(target), "first infected uses canonical Health equipment and containment owners")
    expect(condition_state.has_actor(target) and locomotion_state.has_actor(target) and carry_state.has_actor(target) and skill_state.has_actor(target), "first infected is fully enrolled in shared actor simulation state")

    create_item(mutations, Profiles.SERVICE_PISTOL, GUN)
    create_item(mutations, Profiles.SERVICE_MAGAZINE, OLD_MAG)
    create_item(mutations, Profiles.SERVICE_MAGAZINE, NEW_MAG)
    create_item(mutations, Profiles.SERVICE_ROUND, OLD_ROUND)
    create_item(mutations, Profiles.SERVICE_ROUND, ROUND_A)
    create_item(mutations, Profiles.SERVICE_ROUND, ROUND_B)
    expect(firearm_state.ensure_firearm(GUN) and firearm_state.ensure_magazine(OLD_MAG) and firearm_state.ensure_magazine(NEW_MAG), "exact firearm and magazine containers enroll")
    expect(inventory_mutations.set_container(GUN, Fixture.PLAYER_ID), "exact firearm is carried")
    expect(inventory_mutations.set_container(OLD_MAG, Fixture.PLAYER_ID), "old magazine is carried")
    expect(inventory_mutations.set_container(NEW_MAG, Fixture.PLAYER_ID), "new magazine is carried")
    expect(inventory_mutations.set_container(OLD_ROUND, OLD_MAG), "old exact round is physically inside old magazine")
    expect(inventory_mutations.set_container(ROUND_A, NEW_MAG) and inventory_mutations.set_container(ROUND_B, NEW_MAG), "new exact rounds are physically inside new magazine")
    if not hands.primary_item(Fixture.PLAYER_ID).is_empty(): hand_mutations.clear_slot(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT)
    expect(hand_mutations.set_item(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT, GUN), "exact firearm is assigned to right hand")
    expect(firearm_state.insert_magazine(GUN, OLD_MAG), "old exact magazine is inserted")

    var reload := firearm_actions.request_reload(Fixture.PLAYER_ID)
    var reload_serial := int(reload.get("action_serial", 0))
    var reload_action := kernel.action_by_serial(reload_serial)
    expect(bool(reload.get("accepted", false)) and reload_action != null and reload_action.interruption_policy == Rules.InterruptionPolicy.RESUMABLE, "reload is a real RESUMABLE WHEN action")
    var guard := 0
    while firearm_state.inserted_magazine(GUN) == OLD_MAG and guard < 20:
        kernel.run_next_batch(); guard += 1
    expect(firearm_state.inserted_magazine(GUN).is_empty() and inventory.contains_directly(Fixture.PLAYER_ID, OLD_MAG), "reload eject phase creates truthful intermediate physical state")
    health.apply_damage(Fixture.PLAYER_ID, 1)
    expect(kernel.has_resumable_action(reload_serial), "real damage interrupts reload without erasing progress")
    expect(inventory.contains_directly(Fixture.PLAYER_ID, NEW_MAG), "uninserted exact magazine remains carried while reload is interrupted")
    health.heal(Fixture.PLAYER_ID, 100)
    expect(firearm_actions.resume_reload(reload_serial), "interrupted reload resumes through WHEN")
    kernel.run_until_stop()
    expect(firearm_state.inserted_magazine(GUN) == NEW_MAG, "resume inserts the same exact selected magazine")
    var chambered := firearm_state.chamber_round(GUN)
    expect(chambered == ROUND_A or chambered == ROUND_B, "reload chambers one exact persistent round identity")
    expect(inventory.contains_directly(GUN, chambered), "chambered round is physically contained by firearm")
    expect(firearm_state.magazine_rounds(GUN).size() == 1, "magazine count is derived from remaining exact round identities")

    var player := world.placement(Fixture.PLAYER_ID)
    expect(player != null, "player placement exists")
    expect(mutations.unplace_entity(target), "real infected can be repositioned by physical world mutation for the focused firing scenario")
    var target_cell := find_clear_forward_cell(spatial, player.anchor, player.facing)
    expect(target_cell != Vector2i(-99999, -99999), "found real clear firearm line")
    expect(mutations.set_placement(target, Layers.Channel.ACTOR, target_cell, Facing.opposite(player.facing), Footprint.single_cell()), "resident-backed infected occupies physical firing line")
    create_item(mutations, &"item.prompt.keepsake", KEEPSAKE)
    expect(inventory_mutations.set_container(KEEPSAKE, target), "infected carries exact keepsake")
    expect(hand_mutations.set_item(target, Slots.Value.PRIMARY_RIGHT, KEEPSAKE), "infected equips that same exact keepsake")
    health.apply_damage(target, 70)
    var target_action := kernel.begin_action(target, &"prompt.target.long_action", 50, Rules.InterruptionPolicy.COMMITTED)
    expect(target_action > 0 and kernel.has_active_action(target), "infected has an ordinary active WHEN action before lethal hit")

    var fired_round := firearm_state.chamber_round(GUN)
    var fire := firearm_actions.request_fire(Fixture.PLAYER_ID, Firearms.FIRE_SNAP)
    expect(bool(fire.get("accepted", false)), "snap fire begins as a real timed action")
    kernel.run_until_stop()
    expect(not world.has_entity(fired_round), "discharge consumes the exact chambered live round identity")
    expect(corpse_state.has_corpse_for_actor(target), "lethal firearm consequence triggers generic corpse transition for real infected")
    var corpse_id := corpse_state.corpse_for_actor(target)
    expect(not world.has_placement(target) and world.has_placement(corpse_id), "death removes infected ACTOR occupancy and creates persistent corpse occupancy")
    expect(not kernel.has_active_action(target), "death force-fails infected active WHEN action")
    expect(hands.primary_item(target).is_empty(), "death clears living infected hand assignment")
    expect(inventory.contains_directly(corpse_id, KEEPSAKE), "corpse preserves same exact equipped/carried item identity without loot copying")
    expect(world.has_entity(KEEPSAKE), "preserved corpse item still exists as same WHAT entity")
    expect(infected.is_infected(target) and String(infected.resident_record(target).get("building_id", "")) == String(resident.get("building_id", "")), "corpse transition does not erase population provenance of the source infected")
    var corpse_query := spatial.query_cell(target_cell, Fixture.PLAYER_ID, true)
    expect(corpse_id not in corpse_query.unclassified_entity_ids and corpse_id not in corpse_query.blocking_entity_ids, "corpse has explicit non-blocking collision truth")
    expect(has_combat_sound(sound.presentation_descriptors(Fixture.PLAYER_ID)), "firearm discharge produces physical System-26 combat sound")
    expect(not firearm_state.chamber_round(GUN).is_empty(), "semi-auto cycle advances the remaining exact magazine round into chamber")

    game.queue_free(); await process_frame; finish()

func create_item(mutations: WorldMutationService, semantic: StringName, item_id: String) -> void:
    expect(mutations.create_entity(semantic, item_id) == item_id, "created %s" % item_id)

func find_clear_forward_cell(spatial: SpatialQueryService, origin: Vector2i, facing: int) -> Vector2i:
    var direction := Facing.vector(facing)
    for distance in range(2, 6):
        var all_clear := true
        for step in range(1, distance + 1):
            var cell := origin + direction * step
            if not spatial.has_terrain(cell) or not spatial.query_cell(cell, Fixture.PLAYER_ID, true).is_clear():
                all_clear = false; break
        if all_clear: return origin + direction * distance
    return Vector2i(-99999, -99999)

func _record_exists(records: Array[Dictionary], actor_id: String) -> bool:
    for record: Dictionary in records:
        if String(record.get("resident_id", "")) == actor_id: return true
    return false

func has_combat_sound(descriptors: Array[Dictionary]) -> bool:
    for value: Dictionary in descriptors:
        if String(value.get("category", "")) == "combat": return true
    return false

func expect(ok: bool, message: String) -> void:
    if ok: print("PASS: %s" % message)
    else: failures.append(message); push_error("FAIL: %s" % message)

func finish() -> void:
    if failures.is_empty(): print("PROMPT_COMBAT_FIREARM_DEATH_SMOKE: PASS"); quit(0)
    else:
        push_error("PROMPT_COMBAT_FIREARM_DEATH_SMOKE: FAIL (%d)" % failures.size())
        for value: String in failures: push_error(" - %s" % value)
        quit(1)
