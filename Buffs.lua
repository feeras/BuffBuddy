BuffBuddy = BuffBuddy or {}

-- Buffs without `priority` are suggested independently.
-- Buffs that share the same `class` AND carry a `priority` field compete per target:
-- only the lowest-priority missing spell the caster has learned is shown.
--
-- `ranks` lists every spell ID for the spell from highest rank to lowest.
-- Core:GetBestKnownSpellId() walks this list to find the highest rank the player knows.
BuffBuddy.BUFF_DEFINITIONS = {
    {
        label       = "Power Word: Fortitude",
        spellId     = 21562,
        ranks       = { 21562, 10938, 10937, 2791, 1245, 1244, 1243 },
        rankLevels  = {    60,    58,    50,   38,   26,   14,    4 },
        class       = "PRIEST",
        maxDuration = 3600,
    },
    {
        label         = "Arcane Intellect",
        spellId       = 10157,
        ranks         = { 10157, 10156, 1461, 1460, 1459 },
        rankLevels    = {    56,    42,   28,   14,    1 },
        class         = "MAGE",
        maxDuration   = 3600,
        -- Warriors and Rogues have no mana; INT gives them nothing.
        targetClasses = { MAGE=true, PRIEST=true, WARLOCK=true, DRUID=true, PALADIN=true, SHAMAN=true, HUNTER=true },
    },
    {
        label       = "Mark of the Wild",
        spellId     = 9885,
        ranks       = { 9885, 9884, 8907, 5234, 6756, 5232, 1126 },
        rankLevels  = {   60,   56,   46,   36,   26,   14,    1 },
        class       = "DRUID",
        maxDuration = 3600,
    },

    -- Paladin blessings use priority-based deduplication per target.
    -- Kings:    prio 1 – always offered, no class restriction.
    -- Might:    prio 2 – physical-damage classes (Warrior, Rogue, Hunter, Shaman, Druid).
    -- Wisdom:   prio 2 – pure caster classes (Priest, Mage, Warlock, Paladin).
    -- Sanctuary prio 3 – Paladins only, Protection talent.
    -- Hunter appears in Might only; dedup picks Might over Wisdom at equal priority.
    {
        label       = "Blessing of Kings",
        spellId     = 20217,
        ranks       = { 20217 },
        rankLevels  = {    20 },
        class       = "PALADIN",
        maxDuration = 3600,
        priority    = 1,
    },
    {
        label         = "Blessing of Might",
        spellId       = 25291,
        ranks         = { 25291, 19838, 19837, 19836, 19835, 19834, 19740 },
        rankLevels    = {    60,    52,    42,    32,    22,    12,     4 },
        class         = "PALADIN",
        maxDuration   = 3600,
        priority      = 2,
        targetClasses = { WARRIOR=true, ROGUE=true, HUNTER=true, SHAMAN=true, DRUID=true },
    },
    {
        label         = "Blessing of Wisdom",
        spellId       = 25290,
        ranks         = { 25290, 19854, 19853, 19852, 19850, 19742 },
        rankLevels    = {    60,    52,    42,    32,    22,    14 },
        class         = "PALADIN",
        maxDuration   = 3600,
        priority      = 2,
        targetClasses = { PRIEST=true, MAGE=true, PALADIN=true, WARLOCK=true },
    },
    {
        label         = "Blessing of Sanctuary",
        spellId       = 25899,
        ranks         = { 25899, 20914, 20913, 20912, 20911 },
        rankLevels    = {    60,    50,    40,    30,    20 },
        class         = "PALADIN",
        maxDuration   = 3600,
        priority      = 3,
        targetClasses = { PALADIN=true },
    },
}