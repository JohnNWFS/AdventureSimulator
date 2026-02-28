function sim_apply_party_damage(sim, base_dmg) {
    sim_log_tag(sim, "SPLASH_BEGIN",
        "☠ Splash damage begins (base ~" + string(base_dmg) + ")."
    );

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        // Skip dead/retired/downed bodies
        if (p.dead || p.retired || p.status_state == "downed") {
            continue;
        }

        // Vary damage slightly per member
        var dmg = max(0, base_dmg + sim_rand_range(sim, -1, 1) - p.def);
        if (variable_global_exists("balance") && is_struct(global.balance) && variable_struct_exists(global.balance, "dmg_scalar")) {
            dmg = floor(dmg * global.balance.dmg_scalar);
        }
        var before = p.hp;

        p.hp -= dmg;

        var verbose = variable_global_exists("debug_verbose") ? global.debug_verbose : false;
        if (dmg > 0 || verbose) {
            sim_log_tag(sim, "SPLASH_HIT",
                "☠ SPLASH → " + p.name + " takes " + string(dmg) +
                " (" + string(before) + "→" + string(p.hp) + ")."
            );
        }

        // Immediate downed cue (animation-friendly)
        if (before > 0 && p.hp <= 0) {
            p.downed_this_beat = true;
            sim_log_tag(sim, "DOWNED", "⚠ " + p.name + " is down!");
        }
    }
}
