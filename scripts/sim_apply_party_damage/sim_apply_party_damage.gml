function sim_apply_party_damage(sim, base_dmg) {
    sim_log_tag(sim, "SPLASH_BEGIN",
        "☠ Splash damage begins (base ~" + string(base_dmg) + ")."
    );

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        // Skip dead/retired bodies (they're handled at end-of-beat)
        if (p.dead || p.retired) {
            sim_log_tag(sim, "SPLASH_HIT", "☠ SPLASH → " + p.name + " is gone already.");
            continue;
        }

        // Vary damage slightly per member
        var dmg = max(0, base_dmg + sim_rand_range(sim, -1, 1) - p.def);
        var before = p.hp;

        p.hp -= dmg;

        sim_log_tag(sim, "SPLASH_HIT",
            "☠ SPLASH → " + p.name + " takes " + string(dmg) +
            " (" + string(before) + "→" + string(p.hp) + ")."
        );

        // Immediate downed cue (animation-friendly)
        if (before > 0 && p.hp <= 0) {
            p.downed_this_beat = true;
            sim_log_tag(sim, "DOWNED", "⚠ " + p.name + " is down!");
        }
    }
}
