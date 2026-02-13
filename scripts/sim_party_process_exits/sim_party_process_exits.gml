function sim_party_process_exits(sim, ev) {

    // Only allow retirement rolls at safer beats unless we're retreating.
    var safe_stop = (ev == "merchant" || ev == "relief" || ev == "city_scene" || sim.retreat_to_city);

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        // Keep explicit exit flags in sync with resolve-based retire notices.
        if (p.retire_notice) {
            p.exit_flagged = true;
            p.exit_mode = "retire";
        }

        // Retreat-to-city should hard-commit retirements for flagged members.
        if (sim.retreat_to_city && p.exit_flagged && p.exit_mode == "retire" && !p.dead && !p.retired) {
            p.retired = true;
        }

        // --- Retirement roll (probabilistic) ---
        if (safe_stop && !p.dead && !p.retired) {
            if (p.retire_notice) {
                // Chance rises with wounds and low resolve.
                var wound_push = max(0, (p.wounds - 3) * 8);
                var resolve_pull = max(0, (70 - p.resolve));
                var chance = clamp(12 + wound_push + resolve_pull, 12, 85);

                if (sim_chance(sim, chance)) {
                    p.retired = true;
                }
            }
        }

        if (p.retired) {
            if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "retirements")) {
                sim.stats.retirements += 1;
            }

            sim_log_tag(sim, "RETIRE",
                "🏳 " + p.name + " retires: \"I'm done tempting fate.\""
            );

            // Legacy bump for survivors
            sim_party_apply_legacy(sim, p, "retire");
        }

        // --- Death replacement ---
        if (p.dead) {
            if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "deaths")) {
                sim.stats.deaths += 1;
            }

            sim_log_tag(sim, "FUNERAL",
                "⚰ The party carries " + p.name + " onward in grim silence."
            );

            sim_party_apply_legacy(sim, p, "death");
        }

        // --- Replace if needed (keeps archetype in same slot) ---
        if (p.dead || p.retired) {
            var role_key = "tank";
            var role_name = "Tank";
            var hp = 70, mp = 5, atk = 8, def = 6;

            if (i == 1) { role_key = "mage"; role_name = "Mage"; hp = 40; mp = 30; atk = 12; def = 2; }
            if (i == 2) { role_key = "thief"; role_name = "Thief"; hp = 45; mp = 10; atk = 10; def = 3; }
            if (i == 3) { role_key = "healer"; role_name = "Healer"; hp = 42; mp = 28; atk = 6; def = 3; }

            var new_name = sim_name_pick(sim, role_key);

            sim.party[i] = sim_make_party_member(role_name, new_name, hp, mp, atk, def);

            sim_log_tag(sim, "RECRUIT",
                "🧑 New " + role_name + " joins: " + sim.party[i].name + "."
            );
        }
    }
}

function sim_resolve_city_scene(sim) {
    sim.city_scene_pending = false;
    sim.city_scene_played = true;

    sim_log_tag(sim, "CITY_SCENE",
        "🏙 The party reaches the city walls to triage wounds, mourn losses, and regroup."
    );

    // Clear any stale exit flags from pre-retreat state.
    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        if (p.dead || p.retired) continue;

        if (p.wounds > 0) {
            var heal_wounds = min(2, p.wounds);
            p.wounds -= heal_wounds;
            sim_recalc_derived(p);
            sim_log_tag(sim, "CITY_CARE",
                "🩺 " + p.name + " receives city care (wounds -" + string(heal_wounds) + ")."
            );
        }

        p.exit_flagged = false;
        p.exit_mode = "none";
    }
}
