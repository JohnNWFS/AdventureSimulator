function sim_run_step(sim) {
    if (sim.finished) return;
    if (!variable_struct_exists(sim, "flags") || !is_struct(sim.flags)) sim.flags = {};
    if (!variable_struct_exists(sim.flags, "boss_begun")) sim.flags.boss_begun = false;
    if (!variable_struct_exists(sim, "cine_dungeon_enter_emitted")) sim.cine_dungeon_enter_emitted = false;
    if (!variable_struct_exists(sim, "adventure_initialized")) sim.adventure_initialized = false;
    if (!variable_struct_exists(sim, "city_phase_executed")) sim.city_phase_executed = false;
    if (!variable_struct_exists(sim, "route_generated")) sim.route_generated = is_array(sim.route_segments);
    if (!variable_struct_exists(sim, "cine_tremor_cooldown")) sim.cine_tremor_cooldown = 0;

    // End condition
    if (sim.beat >= sim.beats_target) {
        sim_run_finalize(sim);
        return;
    }

    if (!sim.route_generated || !is_array(sim.route_segments) || array_length(sim.route_segments) <= 0) {
        return;
    }

    var next_route_index = sim.route_index;
    if (sim.beat >= sim.route_milestone_3) next_route_index = 3;
    else if (sim.beat >= sim.route_milestone_2) next_route_index = 2;
    else if (sim.beat >= sim.route_milestone_1) next_route_index = 1;

    if (next_route_index != sim.route_index) {
        sim_log(sim,
            "[DEBUG] route_index advanced " + string(sim.route_index) + "->" + string(next_route_index) +
            " at beat=" + string(sim.beat)
        );
        sim.route_index = next_route_index;

        var transitioned_seg = sim.route_segments[sim.route_index];
        if (transitioned_seg.zone == "Dungeon" && !sim.cine_dungeon_enter_emitted) {
            sim_log_tag(sim, "DUNGEON_ENTER", "The party enters the " + transitioned_seg.dungeon_type + ".");
            sim.cine_dungeon_enter_emitted = true;
        }
    }

    var active_seg = sim.route_segments[sim.route_index];
    sim.zone = active_seg.zone;
    sim.overland_biome = active_seg.biome;
    sim.dungeon_type = active_seg.dungeon_type;
    sim.zone_profile = sim_get_zone_profile(sim);

    var route_label = sim.zone;
    if (sim.zone == "Wilderness") route_label = "Wilderness (" + sim.overland_biome + ")";
    else if (sim.zone == "Dungeon") route_label = "Dungeon (" + sim.dungeon_type + ")";

    // Reset per-zone merchant cap
    if (sim.zone != sim.prev_zone) {
        sim.director.merchants_this_zone = 0;
        sim.director.chests_this_zone = 0;
        sim.prev_zone = sim.zone;
    }

    if (!is_array(sim.recent_beats)) sim.recent_beats = [];

    // Difficulty ramps
    if (sim.beat > 0 && sim.beat % 20 == 0) sim.difficulty += 1;

    if (sim.cine_tremor_cooldown > 0) sim.cine_tremor_cooldown -= 1;

    // Passive MP recovery for casters each beat
    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        if (!sim_party_is_active(p)) continue;

        if (p.role == "Mage") {
            p.mp = min(p.max_mp, p.mp + 2);
        } else if (p.role == "Healer") {
            p.mp = min(p.max_mp, p.mp + 2);
        }
    }

    var zone_key = sim.zone;
    if (sim.zone == "Wilderness") {
        zone_key = "Wilderness: " + sim.overland_biome;
    } else if (sim.zone == "Dungeon") {
        zone_key = "Dungeon: " + sim.dungeon_type;
    }

    var coverage_before = {
        exploration: sim.coverage.exploration,
        social: sim.coverage.social,
        hazard: sim.coverage.hazard,
        merchant: sim.coverage.merchant,
        relief: sim.coverage.relief,
        combat: sim.coverage.combat
    };

    // Director picks the next beat event
    var ev = sim_director_next_event(sim);

    if (ev == "boss" && sim.zone != "Dungeon") {
        var boss_context_relevant = (sim.route_index >= 2);
        if (boss_context_relevant) {
            sim_log(sim,
                "[DEBUG] Boss delayed: not in Dungeon (zone=" + sim.zone +
                " biome=" + sim.overland_biome +
                " route_index=" + string(sim.route_index) + ")"
            );
        }
        if (sim.cine_tremor_cooldown <= 0) {
            var tremor_variants = [
                "A distant tremor hints the lair is near, but not yet.",
                "Stone dust drifts from above; something massive stirs ahead.",
                "A low quake rolls through the corridor, then goes quiet.",
                "The floor shivers once, like a warning from deeper tunnels.",
                "Loose pebbles skitter across the path as the lair breathes nearby.",
                "A deep rumble echoes through the walls, then fades.",
                "The air tightens with a far-off shockwave from below.",
                "Chains and old beams rattle somewhere beyond sight.",
                "A heavy thud carries through the stone, close enough to feel.",
                "The passage groans; whatever waits ahead is awake.",
                "A brief jolt ripples underfoot and the party pauses to listen.",
                "The ground mutters with distant movement near the boss den."
            ];
            sim_log_tag(sim, "COMPLICATION", tremor_variants[0], "", tremor_variants);
            sim.cine_tremor_cooldown = 6;
        }
        ev = "adventure";
    }

    if (ev == "merchant" && sim.director.merchant_cd > 0) {
        sim.director.repeat_prevented += 1;
        ev = "adventure";
    }

    // Playback: why this beat is happening (source cue)
    switch (ev) {
        case "chest":
            sim_log_tag(sim, "BEAT_SOURCE", "🔎 Exploration find: the party spots something ahead in " + route_label + ".", "sim_run_step:source_chest");
            break;
        case "adventure":
            sim_log_tag(sim, "BEAT_SOURCE", "🧭 Expedition: the " + route_label + " route itself forces a decision.", "sim_run_step:source_adventure");
            break;
        case "merchant":
            sim_log_tag(sim, "BEAT_SOURCE", "🧳 Encounter: a merchant appears on the " + route_label + " route.", "sim_run_step:source_merchant");
            break;
        case "relief":
            sim_log_tag(sim, "BEAT_SOURCE", "🛖 Rest stop: the party finds a safe pocket to regroup in " + route_label + ".", "sim_run_step:source_relief");
            break;
        case "city_scene":
            sim_log_tag(sim, "BEAT_SOURCE", "🏙 Return: the party pivots back to city streets before rejoining " + route_label + ".", "sim_run_step:source_city_scene");
            break;
        case "boss":
            sim_log_tag(sim, "BEAT_SOURCE", "👁 Ominous presence: the air shifts near " + route_label + ". Something huge is near.", "sim_run_step:source_boss");
            break;
        case "retreat_bridge":
            sim_log_tag(sim, "BEAT_SOURCE", "🏃 Withdrawal: the party falls back through dangerous ground in " + route_label + ".", "sim_run_step:source_retreat_bridge");
            break;
        case "intro":
            sim_log_tag(sim, "BEAT_SOURCE", "🗺 The party advances deeper into " + route_label + ".", "sim_run_step:source_intro");
            break;
        case "combat":
        default:
            sim_log_tag(sim, "BEAT_SOURCE", "🧭 Danger: movement in the shadows of " + route_label + ".", "sim_run_step:source_combat");
            break;
    }

    switch (ev) {
        case "intro":      sim_resolve_intro(sim); break;
        case "combat":     sim_resolve_combat(sim); break;
        case "chest":      sim_resolve_chest(sim); break;
        case "adventure":  sim_resolve_adventure(sim); break;
        case "merchant":   sim_resolve_merchant(sim); break;
        case "relief":     sim_resolve_relief(sim); break;
        case "retreat_bridge": sim_resolve_retreat_bridge(sim); break;
        case "city_scene": sim_resolve_city_scene(sim); break;
        case "boss":       sim_resolve_boss(sim); break;
        default:             sim_resolve_combat(sim); break;
    }

    if (ev == "boss") {
        sim.flags.boss_begun = true;
        if (variable_struct_exists(sim, "stats") && variable_struct_exists(sim.stats, "boss_trigger_beat") && sim.stats.boss_trigger_beat < 0) {
            sim.stats.boss_trigger_beat = sim.beat;
        }
    }

    var middle_start = floor(sim.beats_target / 3);
    var middle_end = floor((sim.beats_target * 2) / 3);
    if ((!variable_struct_exists(sim.flags, "complication_emitted") || !sim.flags.complication_emitted)
    && sim.beat >= 2
    && sim.beat >= middle_start
    && sim.beat < middle_end
    && !sim.flags.boss_begun) {
        sim.flags.complication_emitted = true;
        var blockade_variants = [
            "A sudden blockade forces the party to burn supplies just to stay on schedule.",
            "Collapsed scaffolding seals the lane, costing rations and rope to clear.",
            "A jammed choke point eats time and supplies before the team can pass.",
            "Broken carts and debris force a hard detour that drains provisions.",
            "An improvised barricade stalls momentum and burns through spare kits.",
            "A narrow kill-lane gets clogged; the party spends tools to reopen it.",
            "A cave-in pinches the route, demanding costly manual clearance.",
            "The corridor buckles, and progress comes at the price of supplies.",
            "A blocked span forces the group to consume gear to keep pace.",
            "A wrecked passage turns into a supply sink before movement resumes.",
            "A jammed corridor grinds progress down until the party pays to push through.",
            "A stonefall barrier stalls the expedition and strips spare resources."
        ];
        sim_log_tag(sim, "COMPLICATION", blockade_variants[0], "", blockade_variants);
    }

    var tension_delta = 0;
    switch (ev) {
        case "combat":
            tension_delta = sim_rand_range(sim, 3, 6);
            break;
        case "merchant":
            tension_delta = -1;
            break;
        case "relief":
            tension_delta = -5;
            break;
        case "adventure":
            if (variable_struct_exists(sim, "last_adventure_tension_outcome")) {
                switch (sim.last_adventure_tension_outcome) {
                    case "hazard": tension_delta = sim_rand_range(sim, 2, 4); break;
                    case "social_positive": tension_delta = -2; break;
                    case "discovery": tension_delta = 1; break;
                }
            }
            break;
    }
    sim.tension_current = max(0, sim.tension_current + tension_delta);

    if (ev == "relief") {
        sim.director.beats_since_relief = 0;
    } else if (ev == "combat" || ev == "adventure" || ev == "retreat_bridge") {
        sim.director.beats_since_relief += 1;
    }

    if (ev == "combat") sim.coverage.combat += 1;
    if (ev == "adventure" || ev == "chest") sim.coverage.exploration += 1;
    if (ev == "retreat_bridge") sim.coverage.retreat += 1;
    if (ev == "merchant") sim.coverage.merchant += 1;
    if (ev == "relief") sim.coverage.relief += 1;

    if (zone_key != "" && variable_struct_exists(sim, "zone_beat_counts")) {
        if (!variable_struct_exists(sim.zone_beat_counts, zone_key)) {
            variable_struct_set(sim.zone_beat_counts, zone_key, {
                combat: 0,
                exploration: 0,
                social: 0,
                hazard: 0,
                merchant: 0,
                relief: 0
            });
        }

        var zone_counts = variable_struct_get(sim.zone_beat_counts, zone_key);
        zone_counts.combat += max(0, sim.coverage.combat - coverage_before.combat);
        zone_counts.exploration += max(0, sim.coverage.exploration - coverage_before.exploration);
        zone_counts.social += max(0, sim.coverage.social - coverage_before.social);
        zone_counts.hazard += max(0, sim.coverage.hazard - coverage_before.hazard);
        zone_counts.merchant += max(0, sim.coverage.merchant - coverage_before.merchant);
        zone_counts.relief += max(0, sim.coverage.relief - coverage_before.relief);
    }

    // Process retirements/deaths and recruit replacements
    sim_party_process_exits(sim, ev);

    // Tension decay (prevents runaway)
    sim.tension = clamp(sim.tension - 2, 0, 100);

    sim.beat += 1;

    sim.director.merchant_cd = max(0, sim.director.merchant_cd - 1);
    sim.director.chest_cd = max(0, sim.director.chest_cd - 1);
    sim.director.adventure_cd = max(0, sim.director.adventure_cd - 1);

    if (is_struct(sim.director.route_mod) && sim.director.route_mod.ttl > 0) {
        sim.director.route_mod.ttl -= 1;
        if (sim.director.route_mod.ttl <= 0) {
            sim.director.route_mod = {
                ambush_mult: 1.0,
                loot_mult: 1.0,
                hazard_mult: 1.0,
                social_mult: 1.0,
                relief_mult: 1.0,
                risk_mult: 1.0,
                ttl: 0,
                label: ""
            };
            var nav_fade_variants = [
                "🧭 Route modifier fades; selection weights normalize.",
                "🧭 The route edge wears off; movement returns to baseline.",
                "🧭 Travel momentum settles and path bias drops to normal.",
                "🧭 Route pressure clears; choices rebalance.",
                "🧭 The temporary route posture expires and pacing evens out.",
                "🧭 Path advantage dissipates; default selection returns.",
                "🧭 The team exits the temporary route state.",
                "🧭 Course conditions normalize as the modifier expires.",
                "🧭 Route tuning ends and default flow resumes.",
                "🧭 The altered route stance fades back to standard.",
                "🧭 Navigation bias drops off; options rebalance.",
                "🧭 Temporary route effects conclude; normal weighting restored."
            ];
            sim_log_tag(sim, "NAV_STATE", nav_fade_variants[0], "", nav_fade_variants);
        }
    }

    array_push(sim.recent_beats, ev);
    if (array_length(sim.recent_beats) > 20) {
        array_delete(sim.recent_beats, 0, 1);
    }
}
