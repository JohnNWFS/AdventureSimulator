function sim_resolve_adventure(sim) {
    var beat = sim_rand_range(sim, 0, 7);
    if (variable_struct_exists(sim.director, "last_adventure_beat") && beat == sim.director.last_adventure_beat) {
        beat = sim_rand_range(sim, 0, 7);
    }
    sim.director.last_adventure_beat = beat;

    switch (beat) {
        case 0:
            sim_log_tag(sim, "NAV_CHOICE", "🧭 Two routes split ahead: a fast ledge path, a safer tunnel, or a backtrack.");
            var nav_roll = sim_rand_range(sim, 0, 99);
            if (nav_roll < 40) {
                sim_apply_route_modifier(sim, "fast");
                sim.gold_total += sim_rand_range(sim, 6, 14);
                sim_log_tag(sim, "NAV_RESULT", "The party sprints the ledge and recovers dropped coin caches.");
            } else if (nav_roll < 75) {
                sim_apply_route_modifier(sim, "safe");
                sim.tension = clamp(sim.tension + 3, 0, 100);
                sim_log_tag(sim, "NAV_RESULT", "They take the safer tunnel and trade speed for control.");
            } else {
                sim_apply_route_modifier(sim, "backtrack");
                sim.tension = clamp(sim.tension - 4, 0, 100);
                sim_log_tag(sim, "NAV_RESULT", "The party backtracks to reset footing, losing time but avoiding pressure.");
            }
            break;
        case 1:
            sim.coverage.hazard += 1;
            sim_log_tag(sim, "HAZARD", "🌫 A spore pocket bursts from the walls.");
            sim_apply_party_damage(sim, sim_rand_range(sim, 2, 5));
            break;
        case 2:
            sim.coverage.discovery += 1;
            sim_log_tag(sim, "DISCOVERY", "🗺 Faded route marks reveal a hidden bypass used by prior delvers.");
            sim.tension = clamp(sim.tension - 7, 0, 100);
            break;
        case 3:
            sim.coverage.social += 1;
            sim_log_tag(sim, "SOCIAL", "🕯 Cult whispers echo nearby; the party catches a password and a warning.");
            sim_log_tag(sim, "RUMOR", "" + sim.zone + " ahead is trapped, but a side hall avoids the kill-box.");
            sim.intel.trap_warning = true;
            break;
        case 4:
            sim.coverage.hazard += 1;
            sim_log_tag(sim, "HAZARD", "🪨 A partial collapse forces the party to drag gear through rubble.");
            sim.tension = clamp(sim.tension + 5, 0, 100);
            if (sim_chance(sim, 35)) sim_apply_party_damage(sim, sim_rand_range(sim, 1, 4));
            break;
        case 5:
            if (!sim.director.discovery_courier_seen) {
                sim.director.discovery_courier_seen = true;
                sim.coverage.discovery += 1;
                sim_log_tag(sim, "DISCOVERY", "🧷 A wounded courier is found with a sealed map fragment.");
                sim.gold_total += sim_rand_range(sim, 4, 10);
                sim_log_tag(sim, "DISCOVERY", "The courier shares a shortcut and a small payment for escort.");
            } else {
                sim.director.repeat_prevented += 1;
                sim_log_tag(sim, "DISCOVERY_PREVENTED", "🧷 Courier discovery suppressed (once per episode). The party finds old camp notes instead.");
                sim.tension = clamp(sim.tension - 2, 0, 100);
            }
            break;
        case 6:
            sim.coverage.social += 1;
            sim_log_tag(sim, "SOCIAL", "⚔ A rival party crosses paths and offers terms: trade supplies for intel.");
            var rivals_roll = sim_rand_range(sim, 0, 99);
            if (rivals_roll < 25) {
                sim_party_restore_mp(sim, sim_rand_range(sim, 2, 6));
                sim_log_tag(sim, "RIVALS_TRADE", "The party trades clean water for spell salts and catches their breath.");
            } else if (rivals_roll < 50) {
                sim_apply_party_damage(sim, sim_rand_range(sim, 1, 3));
                sim.tension = clamp(sim.tension + 6, 0, 100);
                sim_log_tag(sim, "RIVALS_AMBUSH", "Talks are a feint; crossbows snap from the dark before the rivals disengage.");
            } else if (rivals_roll < 75) {
                sim.tension = clamp(sim.tension - 3, 0, 100);
                sim_log_tag(sim, "RIVALS_INFO", "A tense map-side exchange reveals a trapped corridor and a cleaner flank route.");
            } else if (!variable_struct_exists(sim.director, "rivals_stall_seen") || !sim.director.rivals_stall_seen) {
                sim.director.rivals_stall_seen = true;
                sim.tension = clamp(sim.tension + 4, 0, 100);
                sim_log_tag(sim, "TRADE", "Negotiations stall; both groups leave wary and armed.");
            } else {
                sim.tension = clamp(sim.tension - 5, 0, 100);
                sim_log_tag(sim, "RIVALS_ALLIANCE", "Neither side trusts the other, but they coordinate patrol lanes to avoid a mutual wipe.");
            }
            break;
        default:
            if (!sim.director.discovery_major_seen) {
                sim.director.discovery_major_seen = true;
                sim.coverage.discovery += 1;
                sim_log_tag(sim, "DISCOVERY", "📜 Wall runes describe the boss's old rituals and weak points.");
                sim.intel.boss_weakness_known = true;
                sim.tension = clamp(sim.tension - 4, 0, 100);
            } else {
                sim.director.repeat_prevented += 1;
                sim_log_tag(sim, "DISCOVERY_PREVENTED", "📜 Major discovery already logged this episode; details are noted without another breakthrough beat.");
            }
            break;
    }
}
