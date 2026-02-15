function sim_log(sim, text) {
    // Keep in sim's own log (for on-screen display)
    array_push(sim.log, text);

    // Route through beat_output_emit for: debug_lines, file writing, console
    // beat_output_emit handles run_log_text, so we don't touch it here
    beat_output_emit("SIM", text, undefined);
}