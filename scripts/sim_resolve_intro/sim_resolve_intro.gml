function sim_resolve_intro(sim) {
    sim_log(sim, "🧭 The party advances into the " + sim.zone + ".");
}

function sim_resolve_adventure(sim) {
    var beat = sim_rand_range(sim, 0, 7);

    switch (beat) {
        case 0:
            sim_log_tag(sim, "NAV_CHOICE", "🧭 Two routes split ahead: a fast ledge path or a safer tunnel.");
            if (sim_chance(sim, 55)) {
                sim.gold_total += sim_rand_range(sim, 6, 14);
                sim_log_tag(sim, "NAV_RESULT", "The party risks speed and recovers dropped coin caches.");
            } else {
                sim.tension = clamp(sim.tension + 6, 0, 100);
                sim_log_tag(sim, "NAV_RESULT", "They choose caution and lose time while the threat draws closer.");
            }
            break;
        case 1:
            sim_log_tag(sim, "HAZARD", "🌫 A spore pocket bursts from the walls.");
            sim_apply_party_damage(sim, sim_rand_range(sim, 2, 5));
            break;
        case 2:
            sim_log_tag(sim, "DISCOVERY", "🗺 Faded route marks reveal a hidden bypass used by prior delvers.");
            sim.tension = clamp(sim.tension - 7, 0, 100);
            break;
        case 3:
            sim_log_tag(sim, "SOCIAL", "🕯 Cult whispers echo nearby; the party catches a password and a warning.");
            sim_log_tag(sim, "RUMOR", "" + sim.zone + " ahead is trapped, but a side hall avoids the kill-box.");
            break;
        case 4:
            sim_log_tag(sim, "HAZARD", "🪨 A partial collapse forces the party to drag gear through rubble.");
            sim.tension = clamp(sim.tension + 5, 0, 100);
            if (sim_chance(sim, 35)) sim_apply_party_damage(sim, sim_rand_range(sim, 1, 4));
            break;
        case 5:
            sim_log_tag(sim, "DISCOVERY", "🧷 A wounded courier is found with a sealed map fragment.");
            sim.gold_total += sim_rand_range(sim, 4, 10);
            sim_log_tag(sim, "DISCOVERY", "The courier shares a shortcut and a small payment for escort.");
            break;
        case 6:
            sim_log_tag(sim, "SOCIAL", "⚔ A rival party crosses paths and offers terms: trade supplies for intel.");
            if (sim_chance(sim, 50)) {
                sim_party_restore_mp(sim, sim_rand_range(sim, 2, 6));
                sim_log_tag(sim, "TRADE", "The party trades clean water for spell salts and catches their breath.");
            } else {
                sim.tension = clamp(sim.tension + 4, 0, 100);
                sim_log_tag(sim, "TRADE", "Negotiations stall; both groups leave wary and armed.");
            }
            break;
        default:
            sim_log_tag(sim, "DISCOVERY", "📜 Wall runes describe the boss's old rituals and weak points.");
            sim.tension = clamp(sim.tension - 4, 0, 100);
            break;
    }
}

function sim_resolve_retreat_bridge(sim) {
    var bridge = sim_rand_range(sim, 0, 2);

    switch (bridge) {
        case 0:
            sim_log_tag(sim, "RETREAT_DECISION", "🏳 The party votes to pull out before the next push turns fatal.");
            break;
        case 1:
            sim_log_tag(sim, "RETREAT_ROUTE", "🪜 They retrace marked passages while rear guards hold chokepoints.");
            if (sim_chance(sim, 40)) sim_apply_party_damage(sim, sim_rand_range(sim, 1, 3));
            break;
        default:
            sim_log_tag(sim, "GATE_VERDICT", "🚑 At the outer gate, a healer orders immediate treatment and city return.");
            break;
    }
}
