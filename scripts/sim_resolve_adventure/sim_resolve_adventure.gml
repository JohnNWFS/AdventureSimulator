function sim_resolve_adventure(sim) {
    sim.last_adventure_tension_outcome = "none";

    var area_label = sim.zone;
    if (sim.zone == "Wilderness") area_label = sim.overland_biome + " wilderness";
    else if (sim.zone == "Dungeon") area_label = sim.dungeon_type;
    else if (sim.zone == "Town") area_label = "town streets";

    var profile = sim_get_zone_profile(sim);
    var hazard_mult = variable_struct_get(profile.hazard_weights, "spore");
    var collapse_mult = variable_struct_get(profile.hazard_weights, "collapse");
    var whispers_mult = variable_struct_get(profile.social_weights, "whispers");
    var rivals_mult = variable_struct_get(profile.social_weights, "rivals");

    var focus = variable_struct_exists(sim.director, "adventure_focus") ? sim.director.adventure_focus : "";
    var beat_options = [
        { w: 14, v: 0 },
        { w: floor(12 * hazard_mult), v: 1 },
        { w: 12, v: 2 },
        { w: floor(12 * whispers_mult), v: 3 },
        { w: floor(10 * collapse_mult), v: 4 },
        { w: 12, v: 5 },
        { w: floor(12 * rivals_mult), v: 6 },
        { w: 10, v: 7 }
    ];

    if (focus == "hazard") {
        beat_options = [
            { w: floor(14 * hazard_mult), v: 1 },
            { w: floor(12 * collapse_mult), v: 4 },
            { w: 5, v: 0 }
        ];
    } else if (focus == "social") {
        beat_options = [
            { w: floor(13 * whispers_mult), v: 3 },
            { w: floor(13 * rivals_mult), v: 6 },
            { w: 4, v: 2 }
        ];
    } else if (focus == "exploration") {
        beat_options = [
            { w: 14, v: 0 },
            { w: 12, v: 2 },
            { w: 12, v: 5 },
            { w: 10, v: 7 }
        ];
    }

    sim.director.adventure_focus = "";
    var beat = loot_pick_weighted(sim, beat_options);

    if (variable_struct_exists(sim.director, "last_adventure_beat") && beat == sim.director.last_adventure_beat) {
        beat = loot_pick_weighted(sim, [
            { w: 10, v: 0 }, { w: 10, v: 1 }, { w: 10, v: 2 }, { w: 10, v: 3 },
            { w: 10, v: 4 }, { w: 10, v: 5 }, { w: 10, v: 6 }, { w: 10, v: 7 }
        ]);
    }
    sim.director.last_adventure_beat = beat;

    switch (beat) {
        case 0:
            var nav_choice_variants = [
                "🧭 Two routes split ahead: a fast ledge path, a safer tunnel, or a backtrack.",
                "🧭 A three-way fork opens: exposed ledge, cautious tunnel, or fallback trail.",
                "🧭 The corridor branches into speed, safety, or a reset loop behind them.",
                "🧭 Ahead lies a hard choice: gamble the ledge, thread the tunnel, or rewind.",
                "🧭 The map breaks into three lines—quick and risky, slow and stable, or backtrack.",
                "🧭 At the junction, the party weighs pace against control and retreat space.",
                "🧭 A forked hall offers a sprint lane, a defensive lane, and a reverse lane.",
                "🧭 Footprints split at a choke point: push fast, move safe, or reset route.",
                "🧭 Their path divides between an aggressive cut, a guarded crawl, and a step back.",
                "🧭 Three route calls present themselves: press, protect, or pull back.",
                "🧭 The trail fractures into a ledge gamble, a stable tunnel, and a retreat path.",
                "🧭 A fork in the dark forces a choice between tempo, safety, and repositioning."
            ];
            sim_log_tag(sim, "NAV_CHOICE", nav_choice_variants[0], "", nav_choice_variants);
            var nav_roll = sim_rand_range(sim, 0, 99);
            if (nav_roll < 40) {
                sim_apply_route_modifier(sim, "fast");
                sim.gold_total += sim_rand_range(sim, 6, 14);
                sim_log_tag(sim, "NAV_RESULT", "The party sprints the ledge and recovers dropped coin caches.");
            } else if (nav_roll < 75) {
                sim_apply_route_modifier(sim, "safe");
                sim.tension = clamp(sim.tension + floor(3 * profile.tension_modifier), 0, 100);
                sim_log_tag(sim, "NAV_RESULT", "They take the safer tunnel and trade speed for control.");
            } else {
                sim_apply_route_modifier(sim, "backtrack");
                sim.tension = clamp(sim.tension - 4, 0, 100);
                sim_log_tag(sim, "NAV_RESULT", "The party backtracks to reset footing, losing time but avoiding pressure.");
            }
            break;
        case 1:
            sim.coverage.hazard += 1;
            sim.last_adventure_tension_outcome = "hazard";
            sim_log_tag(sim, "HAZARD", "🌫 In the " + area_label + ", a spore pocket bursts from the walls.");
            sim_apply_party_damage(sim, sim_rand_range(sim, 2, 5));
            break;
        case 2:
            sim.coverage.discovery += 1;
            sim.last_adventure_tension_outcome = "discovery";
            var discovery_bypass_variants = [
                "🗺 In the " + area_label + ", faded route marks reveal a hidden bypass used by prior travelers.",
                "🗺 Scored markings in the " + area_label + " uncover a bypass lane tucked behind rubble.",
                "🗺 Old chalk arrows in the " + area_label + " point to a quiet side route.",
                "🗺 Weathered signs in the " + area_label + " expose a narrow bypass corridor.",
                "🗺 The party spots worn trail cuts in the " + area_label + " leading around danger.",
                "🗺 Hidden waymarks in the " + area_label + " reveal a cleaner route forward.",
                "🗺 Scratched symbols in the " + area_label + " map out an overlooked flank path.",
                "🗺 Faint guide marks in the " + area_label + " connect to an old smuggler bypass.",
                "🗺 A sequence of carved cues in the " + area_label + " opens a concealed shortcut.",
                "🗺 Layered trail marks in the " + area_label + " identify a safer hidden branch.",
                "🗺 Dust-covered markers in the " + area_label + " trace a forgotten bypass line.",
                "🗺 Prior expedition glyphs in the " + area_label + " reveal a tucked-away route."
            ];
            sim_log_tag(sim, "DISCOVERY", discovery_bypass_variants[0], "", discovery_bypass_variants);
            sim.tension = clamp(sim.tension - 7, 0, 100);
            break;
        case 3:
            sim.coverage.social += 1;
            sim.last_adventure_tension_outcome = "social_positive";
            sim_log_tag(sim, "SOCIAL", "🕯 Whispers ride through the " + area_label + "; the party catches a password and a warning.");
            sim_log_tag(sim, "RUMOR", "" + area_label + " ahead is trapped, but a side path avoids the kill-box.");
            sim.intel.trap_warning = true;
            break;
        case 4:
            sim.coverage.hazard += 1;
            sim.last_adventure_tension_outcome = "hazard";
            sim_log_tag(sim, "HAZARD", "🪨 A partial collapse in the " + area_label + " forces the party to drag gear through rubble.");
            sim.tension = clamp(sim.tension + floor(5 * profile.tension_modifier), 0, 100);
            if (sim_chance(sim, 35)) sim_apply_party_damage(sim, sim_rand_range(sim, 1, 4));
            break;
        case 5:
            if (!sim.director.discovery_courier_seen) {
                sim.director.discovery_courier_seen = true;
                sim.coverage.discovery += 1;
                var discovery_courier_variants = [
                    "🧷 A wounded courier is found in the " + area_label + " with a sealed map fragment.",
                    "🧷 In the " + area_label + ", the party finds a courier clutching a bloodstained map scrap.",
                    "🧷 A collapsed courier in the " + area_label + " offers a sealed fragment before passing out.",
                    "🧷 The team discovers an injured runner in the " + area_label + " carrying route intel.",
                    "🧷 A courier survivor in the " + area_label + " yields a stitched map segment.",
                    "🧷 Beneath broken gear in the " + area_label + ", a courier hands over a marked fragment.",
                    "🧷 A barely conscious messenger in the " + area_label + " reveals a protected map piece.",
                    "🧷 The party recovers a courier in the " + area_label + " with sealed path notes.",
                    "🧷 In the " + area_label + ", an injured courier trades a map shard for escort.",
                    "🧷 A fallen route-runner in the " + area_label + " reveals a fragment with bypass marks.",
                    "🧷 A courier pinned in the " + area_label + " passes over a wax-sealed path strip.",
                    "🧷 The party finds a wounded courier in the " + area_label + " guarding a critical map piece."
                ];
                sim_log_tag(sim, "DISCOVERY", discovery_courier_variants[0], "", discovery_courier_variants);
                sim.gold_total += sim_rand_range(sim, 4, 10);
                sim_log_tag(sim, "DISCOVERY", "The courier shares a shortcut and a small payment for escort.");
            } else {
                sim.director.repeat_prevented += 1;
                sim_log(sim, "[DEBUG] Courier discovery suppressed (once per episode).");
                sim.tension = clamp(sim.tension - 2, 0, 100);
            }
            break;
        case 6:
            sim.coverage.social += 1;
            sim_log_tag(sim, "SOCIAL", "⚔ A rival party crosses paths in the " + area_label + " and offers terms: trade supplies for intel.");
            var rivals_roll = sim_rand_range(sim, 0, 99);
            if (rivals_roll < 25) {
                sim_party_restore_mp(sim, sim_rand_range(sim, 2, 6));
                sim_log_tag(sim, "RIVALS_TRADE", "The party trades clean water for spell salts and catches their breath.");
            } else if (rivals_roll < 50) {
                sim_apply_party_damage(sim, sim_rand_range(sim, 1, 3));
                sim.tension = clamp(sim.tension + floor(6 * profile.tension_modifier), 0, 100);
                sim_log_tag(sim, "RIVALS_AMBUSH", "Talks are a feint; crossbows snap from the dark before the rivals disengage.");
            } else if (rivals_roll < 75) {
                sim.last_adventure_tension_outcome = "social_positive";
                sim.tension = clamp(sim.tension - 3, 0, 100);
                sim_log_tag(sim, "RIVALS_INFO", "A tense map-side exchange reveals a trapped corridor and a cleaner flank route.");
            } else if (!variable_struct_exists(sim.director, "rivals_stall_seen") || !sim.director.rivals_stall_seen) {
                sim.director.rivals_stall_seen = true;
                sim.tension = clamp(sim.tension + floor(4 * profile.tension_modifier), 0, 100);
                sim_log_tag(sim, "TRADE", "Negotiations stall; both groups leave wary and armed.");
            } else {
                sim.last_adventure_tension_outcome = "social_positive";
                sim.tension = clamp(sim.tension - 5, 0, 100);
                sim_log_tag(sim, "RIVALS_ALLIANCE", "Neither side trusts the other, but they coordinate patrol lanes to avoid a mutual wipe.");
            }
            break;
        default:
            if (!sim.director.discovery_major_seen) {
                sim.director.discovery_major_seen = true;
                sim.coverage.discovery += 1;
                var discovery_major_variants = [
                    "📜 Clues in the " + area_label + " describe the boss's old rituals and weak points.",
                    "📜 Ritual notes in the " + area_label + " expose a weakness pattern in the boss.",
                    "📜 Inscriptions in the " + area_label + " detail how prior hunters cracked the lair defense.",
                    "📜 Ancient records in the " + area_label + " reveal where the boss overcommits.",
                    "📜 The party deciphers lore in the " + area_label + " pointing to exploitable boss habits.",
                    "📜 Fragmented tablets in the " + area_label + " outline a weakness in the boss cadence.",
                    "📜 Old rite markings in the " + area_label + " identify a vulnerable phase in the fight.",
                    "📜 Notes hidden in the " + area_label + " map out the boss's brittle timing window.",
                    "📜 A recovered journal in the " + area_label + " records the boss's failed ritual cycle.",
                    "📜 Etched warnings in the " + area_label + " reveal where the boss can be baited.",
                    "📜 Prior expedition logs in the " + area_label + " describe a reliable break point.",
                    "📜 Sealed lore from the " + area_label + " reveals pressure points in the boss routine."
                ];
                sim_log_tag(sim, "DISCOVERY", discovery_major_variants[0], "", discovery_major_variants);
                sim.intel.boss_weakness_known = true;
                sim.tension = clamp(sim.tension - 4, 0, 100);
            } else {
                sim.director.repeat_prevented += 1;
                sim_log(sim, "[DEBUG] Major discovery suppressed (already logged this episode).");
            }
            break;
    }
}
