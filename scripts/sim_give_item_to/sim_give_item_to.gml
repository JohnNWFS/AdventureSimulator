function sim_give_item_to(sim, item, idx) {
    if (!is_struct(item)) {
        sim_log_tag(sim, "ITEM_ERR", "Tried to give a non-item.");
        return;
    }

    // clamp idx
    idx = clamp(idx, 0, array_length(sim.party) - 1);

    // Treasures convert immediately to gold
    if (item.type == "treasure") {
        sim.gold_total += item.value;
        sim_log_tag(sim, "TREASURE",
            "💰 Treasure: " + item.name + " converts to +" + string(item.value) + " gold."
        );
        return;
    }

    // Consumables: immediate group use
    if (item.type == "consumable") {
        sim_log_tag(sim, "ITEM_GAIN", "🧪 Consumable acquired: " + item.name + ".");

        if (item.use.heal > 0) {
            sim_log_tag(sim, "GROUP_HEAL",
                "✨ " + item.name + " heals +" + string(item.use.heal) + " (group)."
            );
            for (var i = 0; i < array_length(sim.party); i++) {
                var p = sim.party[i];
                var before = p.hp;
                p.hp = min(p.max_hp, p.hp + item.use.heal);
                sim_log_tag(sim, "HP_DELTA",
                    "  ❤️ " + p.name + " HP " + string(before) + "→" + string(p.hp) + "."
                );
            }
        }

        if (item.use.mp > 0) {
            sim_log_tag(sim, "GROUP_MP",
                "🔷 " + item.name + " restores MP +" + string(item.use.mp) + " (group)."
            );
            for (var j = 0; j < array_length(sim.party); j++) {
                var p2 = sim.party[j];
                var before_mp = p2.mp;
                p2.mp = min(p2.max_mp, p2.mp + item.use.mp);
                sim_log_tag(sim, "MP_DELTA",
                    "  🔷 " + p2.name + " MP " + string(before_mp) + "→" + string(p2.mp) + "."
                );
            }
        }

        if (item.use.wound_heal > 0) {
            var healed = 0;
            for (var k = 0; k < array_length(sim.party); k++) {
                if (sim.party[k].wounds > 0) {
                    var w = sim.party[k];
                    var before_wounds = w.wounds;
                    var before_def = w.def;

                    w.wounds = max(0, w.wounds - item.use.wound_heal);
                    sim_recalc_derived(w);

                    sim_log_tag(sim, "WOUND_HEAL",
                        "🩺 " + item.name + ": " + w.name + " recovers " + string(item.use.wound_heal) + " wound."
                    );
                    sim_log_tag(sim, "STAT_DEF",
                        "🟦 DEF " + string(before_def) + "→" + string(w.def) +
                        " (wounds " + string(before_wounds) + "→" + string(w.wounds) + ")."
                    );

                    healed = 1;
                    break;
                }
            }
            if (!healed) {
                sim_log_tag(sim, "WOUND_HEAL",
                    "🩺 " + item.name + ": no wounds to treat."
                );
            }
        }

        return;
    }

    // Equip flow (weapon/armor/trinket)
    var slot = sim_item_slot_from_type(item.type);
    if (slot == "") {
        sim_log_tag(sim, "ITEM_SKIP", "Unknown item type: " + string(item.type) + " (" + item.name + ").");
        return;
    }

    var p = sim.party[idx];

    var before_atk      = p.atk;
    var before_def      = p.def;
    var before_max_hp   = p.max_hp;
    var before_max_mp   = p.max_mp;

    sim_set_equipped_item(p, slot, item);
    sim_recalc_derived(p);

    sim_log_tag(sim, "EQUIP",
        "📦 EQUIP → " + p.name + " equips (" + slot + "): " + item.name + "."
    );

    if (p.atk != before_atk) {
        sim_log_tag(sim, "STAT_ATK",
            "🟩 ATK " + string(before_atk) + "→" + string(p.atk) + "."
        );
    }

    if (p.def != before_def) {
        sim_log_tag(sim, "STAT_DEF",
            "🟦 DEF " + string(before_def) + "→" + string(p.def) + "."
        );
    }

    if (p.max_hp != before_max_hp) {
        sim_log_tag(sim, "STAT_HP",
            "❤️ MAX HP " + string(before_max_hp) + "→" + string(p.max_hp) + "."
        );
    }

    if (p.max_mp != before_max_mp) {
        sim_log_tag(sim, "STAT_MP",
            "🔷 MAX MP " + string(before_max_mp) + "→" + string(p.max_mp) + "."
        );
    }
}
