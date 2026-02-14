function sim_resolve_relief(sim) {
    var relief_opts = ["campfire", "healing shrine", "abandoned outpost", "quiet corridor"];
    var relief_type = relief_opts[sim_rand_range(sim, 0, array_length(relief_opts) - 1)];

    sim_log_tag(sim, "RELIEF_START",
        "🕯 Relief: " + relief_type + ". The party regroups."
    );

    // --- GROUP HEAL ---
    var heal_amt = sim_rand_range(sim, 8, 16) + sim.difficulty;
    sim_log_tag(sim, "GROUP_HEAL",
        "✨ Party heals +" + string(heal_amt) + " (group)."
    );

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        if (p.dead || p.retired) continue;

        var before = p.hp;
        p.hp = min(p.max_hp, p.hp + heal_amt);

        sim_log_tag(sim, "HP_DELTA",
            "  ❤️ " + p.name + " HP " + string(before) + "→" + string(p.hp) + "."
        );
    }

    // --- GROUP MP RESTORE ---
    var mp_amt = sim_rand_range(sim, 6, 14) + floor(sim.difficulty);
    sim_log_tag(sim, "GROUP_MP",
        "🔷 Party restores MP +" + string(mp_amt) + " (group)."
    );

    for (var j = 0; j < array_length(sim.party); j++) {
        var p2 = sim.party[j];
        if (p2.dead || p2.retired) continue;

        var before_mp = p2.mp;
        p2.mp = min(p2.max_mp, p2.mp + mp_amt);

        sim_log_tag(sim, "MP_DELTA",
            "  🔷 " + p2.name + " MP " + string(before_mp) + "→" + string(p2.mp) + "."
        );
    }

    // --- WOUND RECOVERY (all members, scaled) ---
    for (var k = 0; k < array_length(sim.party); k++) {
        var w = sim.party[k];
        if (w.dead || w.retired) continue;
        if (w.wounds <= 0) continue;

        var wound_heal = 1;
        if (w.wounds >= 8) wound_heal = 2;

        var before_wounds = w.wounds;
        var before_def = w.def;

        w.wounds = max(0, w.wounds - wound_heal);
        sim_recalc_derived(w);

        sim_log_tag(sim, "WOUND_HEAL",
            "🩺 Relief treatment: " + w.name + " recovers " + string(wound_heal) + " wound(s)."
        );
        sim_log_tag(sim, "STAT_DEF",
            "🟦 DEF " + string(before_def) + "→" + string(w.def) +
            " (wounds " + string(before_wounds) + "→" + string(w.wounds) + ")."
        );
    }

    // --- Resolve recovery ---
    for (var r = 0; r < array_length(sim.party); r++) {
        var pr = sim.party[r];
        if (pr.dead || pr.retired) continue;

        var before_res = pr.resolve;
        pr.resolve = clamp(pr.resolve + sim_rand_range(sim, 10, 18), 0, 100);

        if (before_res <= 25 || pr.retire_notice) {
            sim_log_tag(sim, "RESOLVE",
                "🧠 " + pr.name + " steadies (" + string(before_res) + "→" + string(pr.resolve) + ")."
            );
        }

        if (pr.resolve > 20) pr.retire_notice = false;
    }

    sim.tension = clamp(sim.tension - 25, 0, 100);
}
