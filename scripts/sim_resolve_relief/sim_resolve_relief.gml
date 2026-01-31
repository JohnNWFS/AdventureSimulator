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

    for (var j = 0; j < array_length(sim.party); j++) {
        var p2 = sim.party[j];
        var before_mp = p2.mp;
        p2.mp = min(p2.max_mp, p2.mp + mp_amt);

        sim_log_tag(sim, "MP_DELTA",
            "  🔷 " + p2.name + " MP " + string(before_mp) + "→" + string(p2.mp) + "."
        );
    }

    // --- WOUND RECOVERY (one member, if any wounds exist) ---
    var wounded_idx = -1;
    for (var k = 0; k < array_length(sim.party); k++) {
        if (sim.party[k].wounds > 0) { wounded_idx = k; break; }
    }

    if (wounded_idx != -1) {
        var w = sim.party[wounded_idx];
        var before_wounds = w.wounds;
        var before_def = w.def;

        w.wounds = max(0, w.wounds - 1);
        sim_recalc_derived(w);

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
