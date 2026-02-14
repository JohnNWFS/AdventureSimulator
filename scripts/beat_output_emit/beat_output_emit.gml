/// @function beat_output_emit(tag, text, data)
/// @desc Canonical emitter for one tagged beat line.
/// @param tag {string}
/// @param text {string}
/// @param data {any} optional struct/map for future use

function beat_output_emit(tag, text, data)
{
    if (!variable_global_exists("debug_lines")) {
        global.debug_lines = [];
        global.debug_line_cap = 80; // default cap
    }

    if (!is_string(tag) || tag == "") tag = "UNTAGGED";
    if (!is_string(text)) text = string(text);

    // Normalize final line
    var line = "[" + tag + "] " + text;

    // Keep buffer capped
    array_push(global.debug_lines, line);
    var cap = global.debug_line_cap;
    while (array_length(global.debug_lines) > cap) {
        array_delete(global.debug_lines, 0, 1);
    }

    // Also send to Output / console for normal debugging
    show_debug_message(line);
}