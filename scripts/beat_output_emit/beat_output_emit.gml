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
    if (!variable_global_exists("canonical_beats")) {
        global.canonical_beats = [];
    }
    if (!variable_global_exists("debug_only_lines")) {
        global.debug_only_lines = [];
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

    // Belt + suspenders: trim UTF-8 BOM from incoming text before tag parsing.
    if (string_length(text) > 0 && ord(string_char_at(text, 1)) == $FEFF) {
        text = string_delete(text, 1, 1);
    }

    // Normalize final line
    var text_starts_tagged = (string_length(text) > 0 && string_char_at(text, 1) == "[");
    var line = text_starts_tagged ? text : ("[" + tag + "] " + text);
    if (string_length(line) > 0 && ord(string_char_at(line, 1)) == $FEFF) {
        line = string_delete(line, 1, 1);
    }

    var route = (is_struct(data) && variable_struct_exists(data, "route")) ? string(data.route) : "both";
    var to_debug = (route != "beat");
    var to_beat = (route != "debug");

    if (tag == "DEBUG" || tag == "CALIB") {
        to_beat = false;
    }
    if (tag == "BEAT_SOURCE") {
        to_beat = false;
        to_debug = true;
    }

    // If caller already provided a tagged beat line (e.g. "[EPISODE_HOOK] ..."),
    // allow beat routing and keep the tag at column 1 with no extra prefix.
    if (tag == "SIM" && text_starts_tagged) {
        to_beat = (route != "debug");
    }

    // Beat log contract: only canonical beat-tagged lines should be emitted there.
    if (line == "" || string_char_at(line, 1) != "[") {
        to_beat = false;
    }
    if (string_pos("[SIM]", line) == 1) {
        to_beat = false;
        to_debug = true;
    }
    if (string_pos("[DEBUG]", line) == 1 || string_pos("[CALIB]", line) == 1) {
        to_beat = false;
        to_debug = true;
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

    if (to_beat) {
        array_push(global.canonical_beats, line);
        global.beat_log_text += line + "\n";
    }
    if (to_debug && !to_beat) {
        array_push(global.debug_only_lines, line);
        global.debug_log_text += line + "\n";
    }

    // ---- Autosave-to-file ----
    // Files are rebuilt from canonical arrays to guarantee deterministic ordering.
    if (global.debug_autosave) {
        if (is_string(global.debug_log_path) && global.debug_log_path != "" && is_string(global.beat_log_path) && global.beat_log_path != "") {
            debug_log_flush();
        }
    }

    // ---- Output / console (existing behavior) ----
    show_debug_message(line);
}
