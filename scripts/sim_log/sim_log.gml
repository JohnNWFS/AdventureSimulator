function sim_log(sim, text) {
    // Keep in sim's own log (for on-screen display)
    array_push(sim.log, text);

    // Route through beat_output_emit for: debug_lines, file writing, console
    // sim_log lines are diagnostics/chatter, so force debug-only routing.
    beat_output_emit("SIM", text, { route : "debug" });
}
