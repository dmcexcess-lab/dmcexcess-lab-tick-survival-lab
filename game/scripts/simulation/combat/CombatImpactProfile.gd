extends RefCounted
class_name CombatImpactProfile

## Physical striking characteristics. Damage is derived by Combat from these facts plus
## real item mass and actor condition; this profile contains no authored damage number.

const BLUNT: StringName = &"blunt"
const EDGE: StringName = &"edge"
const POINT: StringName = &"point"

var semantic_type: StringName = &""
var contact_mode: StringName = BLUNT
var length_cm: int = 0
var rigidity_bp: int = 0
var leverage_bp: int = 0
var balance_bp: int = 0
var contact_transfer_bp: int = 10000

func _init(
    semantic_type_value: StringName = &"",
    contact_mode_value: StringName = BLUNT,
    length_cm_value: int = 0,
    rigidity_bp_value: int = 0,
    leverage_bp_value: int = 0,
    balance_bp_value: int = 0,
    contact_transfer_bp_value: int = 10000
) -> void:
    semantic_type = semantic_type_value
    contact_mode = contact_mode_value
    length_cm = length_cm_value
    rigidity_bp = rigidity_bp_value
    leverage_bp = leverage_bp_value
    balance_bp = balance_bp_value
    contact_transfer_bp = contact_transfer_bp_value

func is_valid() -> bool:
    return not String(semantic_type).strip_edges().is_empty() \
        and contact_mode in [BLUNT, EDGE, POINT] \
        and length_cm > 0 \
        and rigidity_bp >= 1000 and rigidity_bp <= 15000 \
        and leverage_bp >= 1000 and leverage_bp <= 15000 \
        and balance_bp >= 1000 and balance_bp <= 15000 \
        and contact_transfer_bp >= 1000 and contact_transfer_bp <= 20000

func copy() -> CombatImpactProfile:
    return CombatImpactProfile.new(
        semantic_type,
        contact_mode,
        length_cm,
        rigidity_bp,
        leverage_bp,
        balance_bp,
        contact_transfer_bp
    )
