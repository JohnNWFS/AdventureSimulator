function loot_item_score(item) {
    // "Better" == higher POWER.
    // Value is derived from power; power is used for equip/sell decisions.
    return loot_compute_power(item.type, item.tier, item.rarity, item.stats, item.use);
}
