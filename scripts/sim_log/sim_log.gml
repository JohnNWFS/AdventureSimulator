function sim_log(sim, text) {
    if (!is_string(text)) text = string(text);

    // Keep in-memory for HUD
    array_push(sim.log, text);

    // Route through canonical emitter
    beat_output_emit("LOG", text, undefined);
}
