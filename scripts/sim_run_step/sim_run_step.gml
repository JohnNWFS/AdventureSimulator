function sim_run_step(sim) {
    if (sim.finished) return;

    // End condition
    if (sim.beat >= sim.beats_target) {
        sim_run_finalize(sim);
        return;
    }

    // Zone shifts (cheap “season” feel)
    if (sim.beat == 0) sim.zone = "Dungeon";
    if (sim.beat == 35) sim.zone = "Wilderness";
    if (sim.beat == 70) sim.zone = "Town";
    if (sim.beat == 85) sim.zone = "Castle";

    // Difficulty ramps
    if (sim.beat > 0 && sim.beat % 20 == 0) sim.difficulty += 1;

    // Director picks the next beat event
    var ev = sim_director_next_event(sim);

    // Playback: why this beat is happening (source cue)
    switch (ev) {
        case "chest":
            sim_log_tag(sim, "BEAT_SOURCE", "🧭 Exploration find: the party spots something ahead.");
            break;
        case "merchant":
            sim_log_tag(sim, "BEAT_SOURCE", "🧭 Encounter: a traveling merchant appears.");
            break;
        case "relief":
            sim_log_tag(sim, "BEAT_SOURCE", "🧭 Rest stop: the party finds a safe pocket to regroup.");
            break;
        case "boss":
            sim_log_tag(sim, "BEAT_SOURCE", "🧭 Ominous presence: the air shifts. Something huge is near.");
            break;
        case "intro":
            sim_log_tag(sim, "BEAT_SOURCE", "🧭 The party advances deeper.");
            break;
        case "combat":
        default:
            sim_log_tag(sim, "BEAT_SOURCE", "🧭 Danger: movement in the shadows.");
            break;
    }

    switch (ev) {
        case "intro":    sim_resolve_intro(sim); break;
        case "combat":   sim_resolve_combat(sim); break;
        case "chest":    sim_resolve_chest(sim); break;
        case "merchant": sim_resolve_merchant(sim); break;
        case "relief":   sim_resolve_relief(sim); break;
        case "boss":     sim_resolve_boss(sim); break;
        default:         sim_resolve_combat(sim); break;
    }

    // Tension decay (prevents runaway)
    sim.tension = clamp(sim.tension - 2, 0, 100);

    sim.beat += 1;

    sim.director.merchant_cd = max(0, sim.director.merchant_cd - 1);
    sim.director.chest_cd = max(0, sim.director.chest_cd - 1);
}
