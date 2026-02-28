function beat_output_validate_no_consecutive_duplicates(max_examples) {
    var dbg_mode = variable_global_exists("debug_verbose") && global.debug_verbose;
    if (!dbg_mode) return;

    if (!variable_global_exists("debug_only_lines")) global.debug_only_lines = [];
    if (!variable_global_exists("debug_log_text")) global.debug_log_text = "";
    if (!variable_global_exists("run_log_text")) global.run_log_text = "";
    if (!variable_global_exists("canonical_beats")) global.canonical_beats = [];

    var sample_cap = max(1, max_examples);
    var lines = global.canonical_beats;
    var duplicates = 0;
    var samples = [];

    for (var i = 1; i < array_length(lines); i++) {
        if (lines[i] == lines[i - 1]) {
            duplicates += 1;
            if (array_length(samples) < sample_cap) {
                array_push(samples, lines[i]);
            }
        }
    }

    if (duplicates <= 0) return;

    var summary = "[DEBUG] [DUPLICATE_TRIPWIRE] consecutive_duplicates=" + string(duplicates) +
        " inspected=" + string(array_length(lines));
    array_push(global.debug_only_lines, summary);
    global.debug_log_text += summary + "\n";
    global.run_log_text += summary + "\n";
    show_debug_message(summary);

    for (var s = 0; s < array_length(samples); s++) {
        var sample = "[DEBUG] [DUPLICATE_TRIPWIRE] sample[" + string(s) + "]=" + samples[s];
        array_push(global.debug_only_lines, sample);
        global.debug_log_text += sample + "\n";
        global.run_log_text += sample + "\n";
        show_debug_message(sample);
    }
}
