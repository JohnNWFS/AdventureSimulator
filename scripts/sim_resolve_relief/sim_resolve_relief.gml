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

        // Skip dead/retired bodies (they'll be replaced by exit processing)
        if (variable_struct_exists(p, "dead") && p.dead) continue;
        if (variable_struct_exists(p, "retired") && p.retired) continue;

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

        if (variable_struct_exists(p2, "dead") && p2.dead) continue;
        if (variable_struct_exists(p2, "retired") && p2.retired) continue;

        var before_mp = p2.mp;
        p2.mp = min(p2.max_mp, p2.mp + mp_amt);

        sim_log_tag(sim, "MP_DELTA",
            "  🔷 " + p2.name + " MP " + string(before_mp) + "→" + string(p2.mp) + "."
        );
    }

    // --- WOUND RECOVERY (one member) ---
    var wounded_idx = -1;
    for (var k = 0; k < array_length(sim.party); k++) {
        var pk = sim.party[k];
        if ((variable_struct_exists(pk, "dead") && pk.dead) || (variable_struct_exists(pk, "retired") && pk.retired)) continue;
        if (pk.wounds > 0) { wounded_idx = k; break; }
    }

    if (wounded_idx != -1) {
        var w = sim.party[wounded_idx];

        var before_wounds = w.wounds;
        var before_def = w.def;

        w.wounds = max(0, w.wounds - 1);

        // Recalc may normalize equip + derived stats
        sim_recalc_derived(w);

        sim_log_tag(sim, "WOUND_HEAL",
            "🩺 Relief treatment: " + w.name + " recovers 1 wound."
        );
        sim_log_tag(sim, "STAT_DEF",
            "🟦 DEF " + string(before_def) + "→" + string(w.def) +
            " (wounds " + string(before_wounds) + "→" + string(w.wounds) + ")."
        );
    }

    // --- Resolve recovery (subtle, avoids spam) ---
    for (var r = 0; r < array_length(sim.party); r++) {
        var pr = sim.party[r];

        if (variable_struct_exists(pr, "dead") && pr.dead) continue;
        if (variable_struct_exists(pr, "retired") && pr.retired) continue;

        if (!variable_struct_exists(pr, "resolve")) pr.resolve = 100;
        if (!variable_struct_exists(pr, "retire_notice")) pr.retire_notice = false;

        var before_res = pr.resolve;
        pr.resolve = clamp(pr.resolve + sim_rand_range(sim, 10, 18), 0, 100);

        // Only log if they were in the red zone previously
        if (before_res <= 25 || pr.retire_notice) {
            sim_log_tag(sim, "RESOLVE",
                "🧠 " + pr.name + " steadies (" + string(before_res) + "→" + string(pr.resolve) + ")."
            );
        }

        // If they recovered, clear retirement warning
        if (pr.resolve > 20) pr.retire_notice = false;
    }

    sim.tension = clamp(sim.tension - 25, 0, 100);

    // NOTE: Don't call sim_party_process_exits here if you're already calling it from sim_run_step.
    // If you're NOT calling it from sim_run_step, uncomment the next line:
    // sim_party_process_exits(sim, "relief");
}
