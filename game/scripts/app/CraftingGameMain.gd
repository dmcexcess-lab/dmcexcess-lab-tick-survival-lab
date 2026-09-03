extends GameMain
class_name CraftingGameMain

const SkillCheckServiceClass = preload("res://scripts/simulation/actors/skills/ActorSkillCheckService.gd")
const CraftingItemCatalogClass = preload("res://scripts/simulation/crafting/CraftingItemCatalog.gd")
const CraftingRecipeCatalogClass = preload("res://scripts/simulation/crafting/CraftingRecipeCatalog.gd")
const CraftingWorkstationCatalogClass = preload("res://scripts/simulation/crafting/CraftingWorkstationCatalog.gd")
const CraftingPlanQueryClass = preload("res://scripts/simulation/crafting/CraftingPlanQuery.gd")
const CraftingActionServiceClass = preload("res://scripts/simulation/crafting/CraftingActionService.gd")
const CraftingInteractionOfferProviderClass = preload("res://scripts/simulation/crafting/CraftingInteractionOfferProvider.gd")
const CraftingControllerClass = preload("res://scripts/player/CraftingPlayerInteractionController.gd")
const CraftingIconsClass = preload("res://scripts/ui/icons/CraftingSemanticUiIconCatalog.gd")

## Canonical Phase-2 composition extension only. The inherited canonical root still owns
## every preexisting service; this layer composes System 32 through their public seams.

@onready var _crafting_panel: CraftingPanel = $CraftingPanel

var _skill_checks: ActorSkillCheckService = null
var _crafting_items: CraftingItemCatalog = null
var _crafting_recipes: CraftingRecipeCatalog = null
var _crafting_workstations: CraftingWorkstationCatalog = null
var _crafting_plans: CraftingPlanQuery = null
var _crafting_actions: CraftingActionService = null
var _crafting_interaction_offers: CraftingInteractionOfferProvider = null
var _crafting_controller: CraftingPlayerInteractionController = null
var _craft_blocks_interaction: bool = false

func _boot_canonical_demo() -> bool:
    if not super._boot_canonical_demo():
        return false
    return _boot_crafting_runtime()

func _boot_crafting_runtime() -> bool:
    _skill_checks = SkillCheckServiceClass.new(_skill_state)
    if not _skill_checks.is_ready():
        return false
    if _loot_search == null or not _loot_search.configure_skill_checks(_skill_checks):
        return false

    _crafting_items = CraftingItemCatalogClass.new()
    if not _crafting_items.register_physical_profiles(_physical_catalog):
        return false

    _crafting_recipes = CraftingRecipeCatalogClass.new()
    _crafting_workstations = CraftingWorkstationCatalogClass.new()
    _crafting_plans = CraftingPlanQueryClass.new(
        _world,
        _hand_state,
        _inventory_state,
        _carry_query,
        _physical_catalog,
        _crafting_recipes,
        _crafting_items,
        _crafting_workstations,
        _freshness_profiles,
        _interaction_reach
    )
    _crafting_actions = CraftingActionServiceClass.new(
        _world,
        _world_mutations,
        _hand_state,
        _hand_mutations,
        _inventory_state,
        _inventory_mutations,
        _kernel,
        _crafting_recipes,
        _crafting_plans,
        _skill_checks
    )
    _crafting_interaction_offers = CraftingInteractionOfferProviderClass.new(
        _world,
        _crafting_workstations,
        _interaction_reach
    )
    if not _crafting_plans.is_ready() or not _crafting_actions.is_ready() or not _crafting_interaction_offers.is_ready():
        return false
    if not _interaction_affordances.register_provider(_crafting_interaction_offers):
        return false

    # Phase-2 icon vocabulary is additive. Reconfigure existing readers with the
    # Crafting-aware System-31 adapter so crafted items never fall back to unknown art.
    _ui_icons = CraftingIconsClass.new()
    if not _ui_icons.is_ready():
        return false
    if not _shell.configure(_kernel, _stats_inspector, _inventory_inspector, FixtureClass.PLAYER_ID, _ui_icons):
        return false
    if not _loot_panel.configure(_loot_inspection, _inventory_inspector, FixtureClass.PLAYER_ID, _ui_icons):
        return false
    if not _crafting_panel.configure(_crafting_plans, _kernel, FixtureClass.PLAYER_ID, _ui_icons, _skill_checks):
        return false

    _crafting_controller = CraftingControllerClass.new(
        _crafting_actions,
        _interaction_affordances,
        _kernel,
        FixtureClass.PLAYER_ID
    )
    if not _crafting_controller.is_ready():
        return false
    if not _shell.has_signal("crafting_open_requested"):
        return false

    _shell.connect("crafting_open_requested", Callable(_crafting_controller, "request_open_global"))
    _door_pointer.world_cell_primary.connect(Callable(_crafting_controller, "submit_world_cell"))
    _crafting_controller.open_requested.connect(Callable(_crafting_panel, "open_panel"))
    _crafting_panel.craft_requested.connect(Callable(_crafting_controller, "request_craft"))
    _crafting_controller.action_resolved.connect(Callable(_crafting_panel, "present_action_result"))
    _crafting_panel.interaction_blocked_changed.connect(_on_craft_interaction_blocked_changed)
    _refresh_interaction_enabled()
    return true

func _on_craft_interaction_blocked_changed(blocked: bool) -> void:
    _craft_blocks_interaction = blocked
    _refresh_interaction_enabled()

func _refresh_interaction_enabled() -> void:
    var enabled: bool = not _shell_blocks_interaction \
        and not _loot_blocks_interaction \
        and not _craft_blocks_interaction \
        and not _action_blocks_interaction
    _keyboard.set_enabled(enabled)
    _controls.set_enabled(enabled)
    _door_pointer.set_enabled(enabled)
    _camera_input.set_enabled(enabled)
    _camera_controls.set_enabled(enabled)
