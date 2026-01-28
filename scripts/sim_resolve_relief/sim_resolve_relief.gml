function sim_resolve_relief(sim) {
    var relief_type = choose("campfire", "healing shrine", "abandoned outpost", "quiet corridor");

    sim_log_tag(sim, "RELIEF_START",
        "🕯 Relief: " + relief_type + ". The party regroups."
    );

    // --- GROUP HEAL ---
    var heal_amt = sim_rand_range(sim, 6, 14);
    sim_log_tag(sim, "GROUP_HEAL",
        "✨ Party heals +" + string(heal_amt) + " (group)."
    );

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        var before = p.hp;
        p.hp = min(p.max_hp, p.hp + heal_amt);

        sim_log_tag(sim, "HP_DELTA",
            "  ❤️ " + p.name + " HP " + string(before) + "→" + string(p.hp) + "."
        );
    }

    // --- GROUP MP RESTORE ---
    var mp_amt = sim_rand_range(sim, 4, 10);
    sim_log_tag(sim, "GROUP_MP",
        "🔷 Party restores MP +" + string(mp_amt) + " (group)."
    );

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        var before_mp = p.mp;
        p.mp = min(p.max_mp, p.mp + mp_amt);

        sim_log_tag(sim, "MP_DELTA",
            "  🔷 " + p.name + " MP " + string(before_mp) + "→" + string(p.mp) + "."
        );
    }

    // --- WOUND RECOVERY (one member, if any wounds exist) ---
    var wounded_idx = -1;
    for (var i = 0; i < array_length(sim.party); i++) {
        if (sim.party[i].wounds > 0) {
            wounded_idx = i;
            break;
        }
    }

    if (wounded_idx != -1) {
        var w = sim.party[wounded_idx];
        var before_wounds = w.wounds;
        var before_def = w.def;

        w.wounds -= 1;
        w.def = max(0, w.base_def - w.wounds);

        sim_log_tag(sim, "WOUND_HEAL",
            "🩺 Relief treatment: " + w.name + " recovers 1 wound."
        );
        sim_log_tag(sim, "STAT_DEF",
            "🟦 DEF " + string(before_def) + "→" + string(w.def) +
            " (wounds " + string(before_wounds) + "→" + string(w.wounds) + ")."
        );
    }

    sim.tension = clamp(sim.tension - 25, 0, 100);
}
