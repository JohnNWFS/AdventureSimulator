/// @function beat_output_emit(tag, text, data)
/// @desc Canonical emitter for one tagged beat line.
/// @param tag {string}
/// @param text {string}
/// @param data {any} optional struct/map for future use

function beat_output_emit(tag, text, data)
{
    // ---- Ensure core globals exist (backward compatible) ----
    if (!variable_global_exists("debug_lines")) {
        global.debug_lines = [];
    }
    if (!variable_global_exists("debug_line_cap")) {
        global.debug_line_cap = 80; // default cap
    }

    // Optional: capture full run text for clipboard/paste
    if (!variable_global_exists("run_log_text")) {
        global.run_log_text = "";
    }

    if (!variable_global_exists("beat_log_text")) {
        global.beat_log_text = "";
    }
    if (!variable_global_exists("debug_log_text")) {
        global.debug_log_text = "";
    }

    // Optional: autosave-to-file (off by default)
    if (!variable_global_exists("debug_autosave")) {
        global.debug_autosave = false;
    }
    if (!variable_global_exists("debug_log_path")) {
        global.debug_log_path = ""; // set by debug_log_start_file(seed)
    }
    if (!variable_global_exists("beat_log_path")) {
        global.beat_log_path = "";
    }
    if (!variable_global_exists("debug_log_pending")) {
        global.debug_log_pending = ""; // batched file output
    }
    if (!variable_global_exists("debug_log_pending_lines")) {
        global.debug_log_pending_lines = 0;
    }
    if (!variable_global_exists("beat_log_pending")) {
        global.beat_log_pending = "";
    }
    if (!variable_global_exists("beat_log_pending_lines")) {
        global.beat_log_pending_lines = 0;
    }

    // ---- Normalize inputs ----
    if (!is_string(tag) || tag == "") tag = "UNTAGGED";
    if (!is_string(text)) text = string(text);

    // Normalize final line
    var line = "[" + tag + "] " + text;
    var route = (is_struct(data) && variable_struct_exists(data, "route")) ? string(data.route) : "both";
    var to_debug = (route != "beat");
    var to_beat = (route != "debug");

    if (tag == "DEBUG" || tag == "CALIB" || tag == "SIM") {
        to_beat = false;
    }

    // ---- On-screen buffer (existing behavior) ----
    array_push(global.debug_lines, line);
    var cap = global.debug_line_cap;
    while (array_length(global.debug_lines) > cap) {
        array_delete(global.debug_lines, 0, 1);
    }

    // ---- Full run capture (safe, additive) ----
    // Keep it simple: append with newline; caller can clear at run start.
    global.run_log_text += line + "\n";

    if (to_debug) global.debug_log_text += line + "\n";
    if (to_beat) global.beat_log_text += line + "\n";

    // ---- Autosave-to-file (Expectation #3) ----
    // Only writes if autosave is enabled AND a log path has been set.
    // Uses batching to avoid heavy I/O.
    if (global.debug_autosave) {
        if (to_debug && is_string(global.debug_log_path) && global.debug_log_path != "") {
            global.debug_log_pending += line + "\n";
            global.debug_log_pending_lines += 1;
        }
        if (to_beat && is_string(global.beat_log_path) && global.beat_log_path != "") {
            global.beat_log_pending += line + "\n";
            global.beat_log_pending_lines += 1;
        }
        if (global.debug_log_pending_lines >= 25 || global.beat_log_pending_lines >= 25) {
            debug_log_flush();
        }
    }

    // ---- Output / console (existing behavior) ----
    show_debug_message(line);
}
