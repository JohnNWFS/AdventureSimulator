function sim_check_party_health(sim) {

    // Tune knobs here (single source of truth for now)
    var RETIRE_WOUNDS_MIN = 6;      // once you hit this, retirement becomes plausible
    var RETIRE_WOUNDS_HARD = 10;    // very likely retirement once past this
    var RESOLVE_HIT_KD = 12;        // resolve lost on knockdown
    var RESOLVE_HIT_NEAR = 6;       // resolve lost on first near-death trigger

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        // Dead/retired are handled at end-of-beat
        if (p.dead || p.retired) {
            // keep flags tidy
            p.downed_this_beat = false;
            continue;
        }

        // --- TRUE DEATH (rare): catastrophic overkill ---
        // Only if they are driven to <= -max_hp BEFORE the "drag onward" conversion.
        if (p.hp <= -p.max_hp) {
            p.dead = true;
            sim_log_tag(sim, "DEATH",
                "💀 " + p.name + " suffers catastrophic damage and dies (HP " +
                string(p.hp) + " vs -" + string(p.max_hp) + ")."
            );
            p.downed_this_beat = true; // prevents healer from undoing it this beat
            continue;
        }

        // --- DRAG ONWARD (your core rule) ---
        if (p.hp <= 0) {
            p.hp = 1;
            p.wounds += 1;
            p.def = max(0, p.base_def - p.wounds);

            // per-run stats may or may not exist in your branch; guard it
            if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "knockdowns")) {
                sim.stats.knockdowns += 1;
            }

            // Resolve drops when you faceplant into the dirt again
            p.resolve = clamp(p.resolve - RESOLVE_HIT_KD, 0, 100);

            sim_log_tag(sim, "KNOCKDOWN",
                "⚠ " + p.name + " collapses but is dragged onward (HP set to 1)."
            );
            sim_log_tag(sim, "WOUND",
                "🩸 Wounded: " + p.name + " gains a wound (" + string(p.wounds) +
                "). DEF now " + string(p.def) + "."
            );

            // Retirement notice flag (doesn't force retirement, just opens the door)
            if (!p.retire_notice && p.wounds >= RETIRE_WOUNDS_MIN) {
                p.retire_notice = true;
                sim_log_tag(sim, "RETIRE_NOTICE",
                    "🪦 " + p.name + " looks shaken. Retirement is on the table."
                );
            }
        }

        var hp_pct = p.hp / p.max_hp;

        // Near-death trigger
        if (!p.near_death_flag && hp_pct < 0.20) {
            p.near_death_flag = true;

            if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "near_deaths")) {
                sim.stats.near_deaths += 1;
            }

            // First time you hit near-death, it dents resolve too
            p.resolve = clamp(p.resolve - RESOLVE_HIT_NEAR, 0, 100);

            sim_log_tag(sim, "NEAR_DEATH",
                "🚨 Near-death: " + p.name + " is under 20% HP!"
            );

        } else if (p.near_death_flag && hp_pct > 0.35) {
            p.near_death_flag = false;
        }

        // Reset per-beat flag
        p.downed_this_beat = false;

        // Hard retirement notice once you're truly shredded
        if (!p.retire_notice && p.wounds >= RETIRE_WOUNDS_HARD) {
            p.retire_notice = true;
            sim_log_tag(sim, "RETIRE_NOTICE",
                "🪦 " + p.name + " has had enough. They'll likely retire at the next safe stop."
            );
        }
    }
}
