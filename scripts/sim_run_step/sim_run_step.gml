function sim_run_step(sim) {
    if (sim.finished) return;
    if (!variable_struct_exists(sim, "flags") || !is_struct(sim.flags)) sim.flags = {};
    if (!variable_struct_exists(sim.flags, "boss_begun")) sim.flags.boss_begun = false;
    if (!variable_struct_exists(sim, "cine_opening_emitted")) sim.cine_opening_emitted = false;

    // End condition
    if (sim.beat >= sim.beats_target) {
        sim_run_finalize(sim);
        return;
    }

    if (!sim.cine_opening_emitted) {
        var prologue_options = [
            "The party meets in an inn.",
            "The party convenes at the Adventurers' Guild.",
            "The party gathers in the town center.",
            "The party receives a blessing at the local church.",
            "The party consults a priest at the temple.",
            "The party regroups after a battle.",
            "The party arrives by ship and takes rooms near the docks."
        ];
        var prologue_idx = sim_rand_range(sim, 0, array_length(prologue_options) - 1);
        sim_log_tag(sim, "ADVENTURE_START", prologue_options[prologue_idx]);

        var tank_name = "Unknown";
        var thief_name = "Unknown";
        var mage_name = "Unknown";
        var healer_name = "Unknown";

        for (var roster_i = 0; roster_i < array_length(sim.party); roster_i++) {
            var member = sim.party[roster_i];
            if (member.role == "Tank") tank_name = member.name;
            else if (member.role == "Thief") thief_name = member.name;
            else if (member.role == "Mage") mage_name = member.name;
            else if (member.role == "Healer") healer_name = member.name;
        }

        sim_log_tag(sim, "PARTY_ROSTER",
            "Tank=" + tank_name + "; Thief=" + thief_name + "; Mage=" + mage_name + "; Healer=" + healer_name + "."
        );
        sim.cine_opening_emitted = true;
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
        sim.prev_zone = sim.zone;
    }

    if (!is_array(sim.recent_beats)) sim.recent_beats = [];

    // Difficulty ramps
    if (sim.beat > 0 && sim.beat % 20 == 0) sim.difficulty += 1;

    // Passive MP recovery for casters each beat
    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        if (p.dead || p.retired) continue;

        if (p.role == "Mage") {
            p.mp = min(p.max_mp, p.mp + 2);
        } else if (p.role == "Healer") {
            p.mp = min(p.max_mp, p.mp + 2);
        }
    }

    // Director picks the next beat event
    var ev = sim_director_next_event(sim);

    if (ev == "merchant" && sim.director.merchant_cd > 0) {
        sim.director.repeat_prevented += 1;
        ev = "adventure";
    }

    // Playback: why this beat is happening (source cue)
    switch (ev) {
        case "chest":
            sim_log_tag(sim, "BEAT_SOURCE", "🔎 Exploration find: the party spots something ahead in " + route_label + ".");
            break;
        case "adventure":
            sim_log_tag(sim, "BEAT_SOURCE", "🧭 Expedition: the " + route_label + " route itself forces a decision.");
            break;
        case "merchant":
            sim_log_tag(sim, "BEAT_SOURCE", "🧳 Encounter: a merchant appears on the " + route_label + " route.");
            break;
        case "relief":
            sim_log_tag(sim, "BEAT_SOURCE", "🛖 Rest stop: the party finds a safe pocket to regroup in " + route_label + ".");
            break;
        case "city_scene":
            sim_log_tag(sim, "BEAT_SOURCE", "🏙 Return: the party pivots back to city streets before rejoining " + route_label + ".");
            break;
        case "boss":
            sim_log_tag(sim, "BEAT_SOURCE", "👁 Ominous presence: the air shifts near " + route_label + ". Something huge is near.");
            break;
        case "retreat_bridge":
            sim_log_tag(sim, "BEAT_SOURCE", "🏃 Withdrawal: the party falls back through dangerous ground in " + route_label + ".");
            break;
        case "intro":
            sim_log_tag(sim, "BEAT_SOURCE", "🗺 The party advances deeper into " + route_label + ".");
            break;
        case "combat":
        default:
            sim_log_tag(sim, "BEAT_SOURCE", "🧭 Danger: movement in the shadows of " + route_label + ".");
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

    if (ev == "boss") sim.flags.boss_begun = true;

    var middle_start = floor(sim.beats_target / 3);
    var middle_end = floor((sim.beats_target * 2) / 3);
    if ((!variable_struct_exists(sim.flags, "complication_emitted") || !sim.flags.complication_emitted)
    && sim.beat >= 2
    && sim.beat >= middle_start
    && sim.beat < middle_end
    && !sim.flags.boss_begun) {
        sim.flags.complication_emitted = true;
        sim_log(sim, "[COMPLICATION] A sudden blockade forces the party to burn supplies just to stay on schedule.");
    }

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
            sim_log_tag(sim, "NAV_STATE", "🧭 Route modifier fades; selection weights normalize.");
        }
    }

    array_push(sim.recent_beats, ev);
    if (array_length(sim.recent_beats) > 20) {
        array_delete(sim.recent_beats, 0, 1);
    }
}
