function sim_party_process_exits(sim, ev) {

    // Only allow retirement decisions at "safe" beats.
    // Death replacement can happen anytime (because... well... 💀).
    var safe_stop = (ev == "merchant" || ev == "relief");

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        // --- Retirement roll (probabilistic) ---
        if (safe_stop && !p.dead && !p.retired) {
            if (p.retire_notice) {
                // Chance rises with wounds and low resolve.
                // Tuned to be uncommon, not constant.
                var wound_push = max(0, (p.wounds - 5) * 6);         // 6% per wound beyond 5
                var resolve_pull = max(0, (70 - p.resolve));         // lower resolve => higher chance
                var chance = clamp(8 + wound_push + resolve_pull, 8, 70);

                if (sim_chance(sim, chance)) {
                    p.retired = true;

                    if (is_struct(sim.stats) && variable_struct_exists(sim.stats, "retirements")) {
                        sim.stats.retirements += 1;
                    }

                    sim_log_tag(sim, "RETIRE",
                        "🏳 " + p.name + " retires: \"I'm done tempting fate.\""
                    );

                    // Legacy bump for survivors
                    sim_party_apply_legacy(sim, p, "retire");
                }
            }
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