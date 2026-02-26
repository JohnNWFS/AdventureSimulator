function loot_named_table_init() {
    // Small starter set. We'll expand later.
    // NOTE: these are examples; stats/value are intentionally dramatic but still simple.

    var items = [];

    items[array_length(items)] = loot_item_make(
        "named_one_ring", "One Ring", "trinket", 10, "legendary", 5000,
        { atk: 2, def: 2, hp: 20, mp: 20 },
        { heal: 0, mp: 0, wound_heal: 0 },
        ["named", "cursed", "ancient"], "shadow_glow", "equip_trinket", true
    );

    items[array_length(items)] = loot_item_make(
        "named_excalibur", "Excalibur", "weapon", 10, "legendary", 4200,
        { atk: 10, def: 0, hp: 0, mp: 0 },
        { heal: 0, mp: 0, wound_heal: 0 },
        ["named", "holy", "blade"], "holy_glow", "equip_hand", true
    );

    items[array_length(items)] = loot_item_make(
        "named_witches_brew", "Shakespearean Witch's Brew", "consumable", 8, "epic", 1200,
        { atk: 0, def: 0, hp: 0, mp: 0 },
        { heal: 40, mp: 25, wound_heal: 1 },
        ["named", "alchemy"], "green_smoke", "drink", true
    );

    items[array_length(items)] = loot_item_make(
        "named_warden_sigil", "Warden's Sigil", "trinket", 7, "epic", 950,
        { atk: 0, def: 5, hp: 0, mp: 0 },
        { heal: 0, mp: 0, wound_heal: 0 },
        ["named", "castle"], "steel_spark", "equip_trinket", true
    );

    items[array_length(items)] = loot_item_make(
        "named_ember_circlet", "Ember Circlet", "trinket", 6, "rare", 650,
        { atk: 2, def: 1, hp: 0, mp: 8 },
        { heal: 0, mp: 0, wound_heal: 0 },
        ["named", "fire"], "ember_glow", "equip_trinket", true
    );

    return items;
}
