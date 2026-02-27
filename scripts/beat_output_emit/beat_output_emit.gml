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
    if (!variable_global_exists("debug_output_enabled")) {
        global.debug_output_enabled = false;
    }

    if (!variable_global_exists("last_emitted_line")) {
        global.last_emitted_line = "";
    }
    if (!variable_global_exists("last_emitted_tag")) {
        global.last_emitted_tag = "";
    }
    if (!variable_global_exists("last_emitted_source")) {
        global.last_emitted_source = "";
    }
    if (!variable_global_exists("duplicate_suppressed_count")) {
        global.duplicate_suppressed_count = 0;
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
    var tag_upper = string_upper(tag);
    var suppression_tag = (string_pos("_SUPPRESSED", tag_upper) > 0 || string_pos("_PREVENTED", tag_upper) > 0);
    if (suppression_tag) {
        if (global.debug_output_enabled) {
            route = "debug";
        } else {
            return false;
        }
    }

    var sim = (is_struct(data) && variable_struct_exists(data, "sim") && is_struct(data.sim)) ? data.sim : undefined;
    var source = (is_struct(data) && variable_struct_exists(data, "source")) ? string(data.source) : "";
    var to_debug = (route != "beat");
    var to_beat = (route != "debug");

    if (!global.debug_output_enabled) {
        to_debug = false;
    }

    if (tag == "DEBUG" || tag == "CALIB") {
        to_beat = false;
    }
    if (tag == "BEAT_SOURCE") {
        to_beat = false;
        to_debug = true;
    }

    if (!global.debug_output_enabled) {
        to_debug = false;
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

    var gate_checked = (tag == "EPISODE_BEGIN" || tag == "EPISODE_END");
    var gate_allowed = true;
    var gate_source = "none";

    if (gate_checked && to_beat) {
        if (is_struct(sim)) {
            if (!variable_struct_exists(sim, "flags") || !is_struct(sim.flags)) sim.flags = {};

            var flag_name = (tag == "EPISODE_BEGIN") ? "episode_begin_emitted" : "episode_end_emitted";
            var already_emitted = (variable_struct_exists(sim.flags, flag_name) && variable_struct_get(sim.flags, flag_name));
            if (already_emitted) {
                gate_allowed = false;
                gate_source = "sim.flags";
            } else {
                variable_struct_set(sim.flags, flag_name, true);
                gate_source = "sim.flags";
            }
        }

        if (gate_allowed) {
            for (var episode_i = 0; episode_i < array_length(global.canonical_beats); episode_i++) {
                if (string_pos("[" + tag + "]", global.canonical_beats[episode_i]) == 1) {
                    gate_allowed = false;
                    if (gate_source == "none") gate_source = "canonical_beats";
                    break;
                }
            }
            if (gate_source == "none") gate_source = "canonical_beats";
        }

        if (!gate_allowed) {
            to_beat = false;
            to_debug = true;
        }
    }

    var duplicate_attempt = (line == global.last_emitted_line);
    if (duplicate_attempt) {
        global.duplicate_suppressed_count += 1;

        var duplicate_debug_enabled = variable_global_exists("debug_verbose") && global.debug_verbose;
        if (duplicate_debug_enabled) {
            var duplicate_source = source;
            if (duplicate_source == "" && is_struct(sim)) {
                duplicate_source = "sim_run_step@beat=" + string(sim.beat);
            }
            if (duplicate_source == "") duplicate_source = "unknown";

            var duplicate_line = "[DEBUG] [DUPLICATE_SUPPRESSED] tag=" + tag +
                " source=" + duplicate_source +
                " attempted=\"" + line + "\"" +
                " previous=\"" + global.last_emitted_line + "\"";
            array_push(global.debug_only_lines, duplicate_line);
            global.debug_log_text += duplicate_line + "\n";
            global.run_log_text += duplicate_line + "\n";
            if (global.debug_output_enabled) show_debug_message(duplicate_line);
        }

        return false;
    }

    // ---- On-screen buffer (existing behavior) ----
    if (global.debug_output_enabled) {
        array_push(global.debug_lines, line);
        var cap = global.debug_line_cap;
        while (array_length(global.debug_lines) > cap) {
            array_delete(global.debug_lines, 0, 1);
        }
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

    if (gate_checked && variable_global_exists("debug_verbose") && global.debug_verbose) {
        var phase = "unknown";
        if (is_struct(sim)) {
            if (variable_struct_exists(sim, "zone") && is_string(sim.zone)) phase = sim.zone;
            if (variable_struct_exists(sim, "beat")) phase += "@beat=" + string(sim.beat);
        }
        var gate_line = "[DEBUG] [EPISODE_TAG_GATE] tag=" + tag +
            " allowed=" + string(gate_allowed) +
            " source=" + gate_source +
            " phase=" + phase;
        array_push(global.debug_only_lines, gate_line);
        global.debug_log_text += gate_line + "\n";
        global.run_log_text += gate_line + "\n";
        if (global.debug_output_enabled) show_debug_message(gate_line);
    }

    // ---- Autosave-to-file ----
    // Files are rebuilt from canonical arrays to guarantee deterministic ordering.
    if (global.debug_autosave) {
        if (is_string(global.debug_log_path) && global.debug_log_path != "" && is_string(global.beat_log_path) && global.beat_log_path != "") {
            debug_log_flush();
        }
    }

    // ---- Output / console (existing behavior) ----
    global.last_emitted_line = line;
    global.last_emitted_tag = tag;
    global.last_emitted_source = source;
    if (global.debug_output_enabled) show_debug_message(line);
    return true;
}
