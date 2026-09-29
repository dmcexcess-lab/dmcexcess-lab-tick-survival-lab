extends GameMain
class_name CraftingGameMain

const SkillCheckServiceClass = preload("res://scripts/simulation/actors/skills/ActorSkillCheckService.gd")
const CraftingItemCatalogClass = preload("res://scripts/simulation/crafting/CraftingItemCatalog.gd")
const CraftingRecipeCatalogClass = preload("res://scripts/simulation/crafting/CraftingRecipeCatalog.gd")
const CraftingWorkstationCatalogClass = preload("res://scripts/simulation/crafting/CraftingWorkstationCatalog.gd")
const CraftingPlanQueryClass = preload("res://scripts/simulation/crafting/CraftingPlanQuery.gd")
const CraftingInteractionOfferProviderClass = preload("res://scripts/simulation/crafting/CraftingInteractionOfferProvider.gd")
const CraftingIconsClass = preload("res://scripts/ui/icons/CraftingSemanticUiIconCatalog.gd")
const OutdoorForageStateClass = preload("res://scripts/simulation/forage/OutdoorForageState.gd")
const ForageNearbyActionClass = preload("res://scripts/simulation/forage/ForageNearbyActionService.gd")

@onready var _crafting_panel: CraftingPanel = $CraftingPanel
var _skill_checks: ActorSkillCheckService = null
var _crafting_items: CraftingItemCatalog = null
var _crafting_recipes: CraftingRecipeCatalog = null
var _crafting_workstations: CraftingWorkstationCatalog = null
var _crafting_plans: CraftingPlanQuery = null
var _crafting_interaction_offers: CraftingInteractionOfferProvider = null
var _forage_state: OutdoorForageState = null
var _forage_actions: ForageNearbyActionService = null
var _craft_blocks_interaction: bool = false

func _boot_production_world() -> bool:
    if not super._boot_production_world(): return false
    return _boot_crafting_runtime()

func _boot_crafting_runtime() -> bool:
    _skill_checks = SkillCheckServiceClass.new(_skill_state)
    if not _skill_checks.is_ready(): return false
    _forage_state = OutdoorForageStateClass.new()
    _forage_actions = ForageNearbyActionClass.new(_world, _world_mutations, _kernel, _skill_checks, _loot_items, WorldBootstrapClass.active_seed(), _forage_state, _inventory_mutations, _carry_acquisition)
    if not _forage_actions.is_ready(): return false
    if not _controls.forage_requested.is_connected(_on_forage_requested): _controls.forage_requested.connect(_on_forage_requested)
    _forage_actions.forage_completed.connect(_on_forage_completed)
    _forage_actions.forage_failed.connect(_on_forage_failed)
    _forage_actions.forage_canceled.connect(_on_forage_canceled)
    _crafting_items = CraftingItemCatalogClass.new()
    if not _crafting_items.register_physical_profiles(_physical_catalog): return false
    _crafting_recipes = CraftingRecipeCatalogClass.new()
    _crafting_workstations = CraftingWorkstationCatalogClass.new()
    _crafting_plans = CraftingPlanQueryClass.new(_world, _hand_state, _inventory_state, _carry_query, _physical_catalog, _crafting_recipes, _crafting_items, _crafting_workstations, _freshness_profiles, _interaction_reach)
    _crafting_interaction_offers = CraftingInteractionOfferProviderClass.new(_world, _crafting_workstations, _interaction_reach)
    if not _crafting_plans.is_ready() or not _crafting_interaction_offers.is_ready(): return false
    if not _interaction_affordances.register_provider(_crafting_interaction_offers): return false
    _ui_icons = CraftingIconsClass.new()
    if not _ui_icons.is_ready(): return false
    if not _shell.configure(_kernel, _stats_inspector, _inventory_inspector, WorldBootstrapClass.PLAYER_ID, _ui_icons): return false
    if not _loot_panel.configure(_loot_inspection, _inventory_inspector, WorldBootstrapClass.PLAYER_ID, _ui_icons): return false
    if not _crafting_panel.configure(_crafting_plans, _kernel, WorldBootstrapClass.PLAYER_ID, _ui_icons, _skill_checks): return false
    if not _shell.has_signal("crafting_open_requested"): return false
    if not _shell.crafting_open_requested.is_connected(_on_global_crafting_open_requested): _shell.crafting_open_requested.connect(_on_global_crafting_open_requested)
    _crafting_panel.interaction_blocked_changed.connect(_on_craft_interaction_blocked_changed)
    _refresh_interaction_enabled()
    return true

func _on_global_crafting_open_requested() -> void:
    if _crafting_panel != null: _crafting_panel.open_panel("")

func _on_forage_requested() -> void:
    if _forage_actions == null or _kernel == null or _kernel.is_hard_paused(): return
    var request: Dictionary = _forage_actions.request_forage(WorldBootstrapClass.PLAYER_ID)
    if bool(request.get("accepted", false)): _kernel.run_until_stop()
    elif _hud != null: _hud.present_action_result(ForageNearbyActionClass.ACTION_TYPE, false, String(request.get("reason", "forage_rejected")), _kernel.world_tick())
func _on_forage_completed(actor_id: String, _serial: int, _patch_key: String, _item_ids: Variant, _semantics: Variant) -> void:
    if actor_id == WorldBootstrapClass.PLAYER_ID and _hud != null: _hud.present_action_result(ForageNearbyActionClass.ACTION_TYPE, true, "", _kernel.world_tick())
func _on_forage_failed(actor_id: String, _serial: int, _patch_key: String, reason: String, _opportunity_consumed: bool) -> void:
    if actor_id == WorldBootstrapClass.PLAYER_ID and _hud != null: _hud.present_action_result(ForageNearbyActionClass.ACTION_TYPE, false, reason, _kernel.world_tick())
func _on_forage_canceled(actor_id: String, _serial: int, _patch_key: String, reason: String) -> void:
    if actor_id == WorldBootstrapClass.PLAYER_ID and _hud != null: _hud.present_action_result(ForageNearbyActionClass.ACTION_TYPE, false, reason, _kernel.world_tick())
func _on_craft_interaction_blocked_changed(blocked: bool) -> void:
    _craft_blocks_interaction = blocked
    _refresh_interaction_enabled()
func _refresh_interaction_enabled() -> void:
    var enabled: bool = not _shell_blocks_interaction and not _loot_blocks_interaction and not _craft_blocks_interaction and not _action_blocks_interaction
    _keyboard.set_enabled(enabled)
    _controls.set_enabled(enabled)
    _door_pointer.set_enabled(enabled)
    _camera_input.set_enabled(enabled)
    _camera_controls.set_enabled(enabled)
