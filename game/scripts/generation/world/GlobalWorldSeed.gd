extends RefCounted
class_name GlobalWorldSeed

## Stable named sub-seeds for System 00D. Global planning must not depend on
## call-order consumption from one shared RNG.

const HASH_MASK: int = 0x7fffffff

static func derive(base_seed: int, domain: String) -> int:
    var value: int = base_seed & HASH_MASK
    for index in range(domain.length()):
        value = int((value * 1103515245 + domain.unicode_at(index) + 12345) & HASH_MASK)
    return value

static func choose_index(base_seed: int, domain: String, count: int) -> int:
    if count <= 0:
        return -1
    return derive(base_seed, domain) % count

static func choose_inclusive(base_seed: int, domain: String, minimum: int, maximum: int) -> int:
    if maximum < minimum:
        return minimum
    var span: int = maximum - minimum + 1
    return minimum + choose_index(base_seed, domain, span)
