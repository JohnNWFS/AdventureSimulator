function sim_give_item(sim, item_name) {
    var idx = sim_rand_range(sim, 0, 3);
    var slot = "trinket";

    // crude slot mapping
    if (string_pos("Wand", item_name) > 0 || item_name == "Spell Scroll") slot = "weapon";
    if (string_pos("Helm", item_name) > 0 || string_pos("Shield", item_name) > 0 || item_name == "Armor Patch") slot = "armor";
    if (string_pos("Vial", item_name) > 0 || item_name == "Health Tonic") slot = "consumable";

    // owner mapping for a few signature items
    if (item_name == "Mirror Dagger") idx = 2;
    if (item_name == "Saint's Charm") idx = 3;
    if (item_name == "Ember Ring") idx = 1;

    var p = sim.party[idx];

    // Snapshot stats for delta logging
    var before_atk      = p.atk;
    var before_base_def = p.base_def;
    var before_def      = p.def;

    switch (slot) {
        case "weapon":      p.weapon = item_name; break;
        case "armor":       p.armor = item_name; break;
        case "trinket":     p.trinket = item_name; break;
        case "consumable":  p.consumable = item_name; break;
    }

    // --- Item effects (keep tiny + explicit) ---
    if (item_name == "Warden's Sigil") {
        p.base_def += 5;
    } else if (item_name == "Ogre King's Tooth") {
        p.atk += 2;
    } else if (item_name == "Crown Shard") {
        p.atk += 1;
        p.base_def += 1;
    }

    // Recompute def from base_def and wounds
    p.def = max(0, p.base_def - p.wounds);

    sim_log_tag(sim, "EQUIP",
        "📦 EQUIP → " + p.name + " equips (" + slot + "): " + item_name + "."
    );

    if (p.atk != before_atk) {
        sim_log_tag(sim, "STAT_ATK",
            "🟩 ATK " + string(before_atk) + "→" + string(p.atk) + "."
        );
    }

    if (p.base_def != before_base_def || p.def != before_def) {
        sim_log_tag(sim, "STAT_DEF",
            "🟦 DEF " + string(before_def) + "→" + string(p.def) +
            " (base " + string(before_base_def) + "→" + string(p.base_def) + ")."
        );
    }
}
