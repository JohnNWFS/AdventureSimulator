function sim_run_step(sim) {
    if (sim.finished) return;

    // End condition
    if (sim.beat >= sim.beats_target) {
        sim_run_finalize(sim);
        return;
    }

    // Zone shifts
    if (sim.beat == 0) sim.zone = "Dungeon";
    if (sim.beat == 35) sim.zone = "Wilderness";
    if (sim.beat == 70) sim.zone = "Town";
    if (sim.beat == 85) sim.zone = "Castle";

    // Reset per-zone merchant cap
    if (sim.zone != sim.prev_zone) {
        sim.director.merchants_this_zone = 0;
        sim.prev_zone = sim.zone;
    }

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

    // Playback: why this beat is happening (source cue)
    switch (ev) {
        case "chest":
            sim_log_tag(sim, "BEAT_SOURCE", "🔎 Exploration find: the party spots something ahead.");
            break;
        case "merchant":
            sim_log_tag(sim, "BEAT_SOURCE", "🧳 Encounter: a traveling merchant appears.");
            break;
        case "relief":
            sim_log_tag(sim, "BEAT_SOURCE", "🛖 Rest stop: the party finds a safe pocket to regroup.");
            break;
        case "city_scene":
            sim_log_tag(sim, "BEAT_SOURCE", "🏙 Return: the party pivots back to city streets.");
            break;
        case "boss":
            sim_log_tag(sim, "BEAT_SOURCE", "👁 Ominous presence: the air shifts. Something huge is near.");
            break;
        case "intro":
            sim_log_tag(sim, "BEAT_SOURCE", "🗺 The party advances deeper.");
            break;
        case "combat":
        default:
            sim_log_tag(sim, "BEAT_SOURCE", "🧭 Danger: movement in the shadows.");
            break;
    }

    switch (ev) {
        case "intro":      sim_resolve_intro(sim); break;
        case "combat":     sim_resolve_combat(sim); break;
        case "chest":      sim_resolve_chest(sim); break;
        case "merchant":   sim_resolve_merchant(sim); break;
        case "relief":     sim_resolve_relief(sim); break;
        case "city_scene": sim_resolve_city_scene(sim); break;
        case "boss":       sim_resolve_boss(sim); break;
        default:             sim_resolve_combat(sim); break;
    }

    if (ev == "relief") {
        sim.director.beats_since_relief = 0;
    } else if (ev == "combat") {
        sim.director.beats_since_relief += 1;
    }

    // Process retirements/deaths and recruit replacements
    sim_party_process_exits(sim, ev);

    // Tension decay (prevents runaway)
    sim.tension = clamp(sim.tension - 2, 0, 100);

    sim.beat += 1;

    sim.director.merchant_cd = max(0, sim.director.merchant_cd - 1);
    sim.director.chest_cd = max(0, sim.director.chest_cd - 1);
}
