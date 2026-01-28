function sim_check_party_health(sim) {
    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        if (p.hp <= 0) {
            p.hp = 1;
            p.wounds += 1;
            p.def = max(0, p.base_def - p.wounds);
            sim.stats.knockdowns += 1;

            sim_log_tag(sim, "KNOCKDOWN",
                "⚠ " + p.name + " collapses but is dragged onward (HP set to 1)."
            );
            sim_log_tag(sim, "WOUND",
                "🩸 Wounded: " + p.name + " gains a wound (" + string(p.wounds) +
                "). DEF now " + string(p.def) + "."
            );
        }

        var hp_pct = p.hp / p.max_hp;

        if (!p.near_death_flag && hp_pct < 0.20) {
            p.near_death_flag = true;
            sim.stats.near_deaths += 1;

            sim_log_tag(sim, "NEAR_DEATH",
                "🚨 Near-death: " + p.name + " is under 20% HP!"
            );
        } else if (p.near_death_flag && hp_pct > 0.35) {
            p.near_death_flag = false;
        }

        // Reset per-beat flag
        p.downed_this_beat = false;
    }
}
