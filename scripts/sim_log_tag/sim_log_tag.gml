function sim_log_tag(sim, tag, msg) {
    // Keep in sim's own log (for on-screen display)
    array_push(sim.log, "[" + string(tag) + "] " + msg);

    // Route through beat_output_emit for file + console
    beat_output_emit(tag, msg, { sim: sim });
}
