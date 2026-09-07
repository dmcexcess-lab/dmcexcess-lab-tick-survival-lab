extends RefCounted
class_name ActorDeathTransitionService

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

const CORPSE_SEMANTIC: StringName = &"object.corpse"

signal actor_died(actor_id, corpse_id)

var _world: WorldState = null
var _world_mutations: WorldMutationService = null
var _kernel: TickKernel = null
var _health: ActorHealthState = null
var _hands: ActorHandEquipmentState = null
var _hand_mutations: ActorHandEquipmentMutationService = null
var _inventory: InventoryContainmentState = null
var _inventory_mutations: InventoryContainmentMutationService = null
var _corpses: CorpseState = null

func _init(world=null, world_mutations=null, kernel=null, health=null, hands=null, hand_mutations=null, inventory=null, inventory_mutations=null, corpses=null) -> void:
    _world=world; _world_mutations=world_mutations; _kernel=kernel; _health=health; _hands=hands; _hand_mutations=hand_mutations
    _inventory=inventory; _inventory_mutations=inventory_mutations; _corpses=corpses
    if _health != null: _health.hp_changed.connect(_on_hp_changed)

func is_ready() -> bool:
    return _world != null and _world_mutations != null and _kernel != null and _health != null and _hands != null and _hand_mutations != null and _inventory != null and _inventory_mutations != null and _corpses != null

func transition_if_dead(actor_id: String) -> String:
    if not is_ready() or not _health.has_actor(actor_id) or _health.current_hp(actor_id) > 0: return ""
    if _corpses.has_corpse_for_actor(actor_id): return _corpses.corpse_for_actor(actor_id)
    if not _world.has_entity(actor_id): return ""
    var placement := _world.placement(actor_id)
    if placement == null: return ""

    var active := _kernel.active_action_for_actor(actor_id)
    if active != null: _kernel.fail_action(active.serial, "actor_dead")

    var corpse_id := "corpse.%s" % actor_id
    if _world.has_entity(corpse_id): return ""
    if _world_mutations.create_entity(CORPSE_SEMANTIC, corpse_id) != corpse_id: return ""
    if not _inventory_mutations.enroll_container(corpse_id):
        _world_mutations.remove_entity(corpse_id); return ""

    var right := _hands.primary_item(actor_id)
    var left := _hands.secondary_item(actor_id)
    if not right.is_empty(): _hand_mutations.clear_slot(actor_id, Slots.Value.PRIMARY_RIGHT)
    if not left.is_empty(): _hand_mutations.clear_slot(actor_id, Slots.Value.SECONDARY_LEFT)

    var carried := _inventory.direct_contents(actor_id)
    for item_id: String in carried:
        if not _inventory_mutations.set_container(item_id, corpse_id):
            return ""

    if not _world_mutations.unplace_entity(actor_id): return ""
    if not _world_mutations.set_placement(corpse_id, Layers.Channel.OBJECT, placement.anchor, placement.facing, placement.footprint, placement.structure_axis): return ""
    if not _corpses.record(actor_id, corpse_id): return ""
    actor_died.emit(actor_id, corpse_id)
    return corpse_id

func _on_hp_changed(actor_id: String, previous_hp: int, hp: int, _max_hp: int, _version: int) -> void:
    if previous_hp > 0 and hp <= 0:
        transition_if_dead(actor_id)
