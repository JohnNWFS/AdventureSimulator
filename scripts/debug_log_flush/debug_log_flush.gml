function debug_log_flush()
{
    if (variable_global_exists("beat_log_path") && is_string(global.beat_log_path) && global.beat_log_path != "") {
        var beat_lines = variable_global_exists("canonical_beats") ? global.canonical_beats : [];
        var f_beat = file_text_open_write(global.beat_log_path);
        for (var i = 0; i < array_length(beat_lines); i++) {
            file_text_write_string(f_beat, beat_lines[i] + "\n");
        }
        file_text_close(f_beat);
    }

    if (variable_global_exists("debug_log_path") && is_string(global.debug_log_path) && global.debug_log_path != "") {
        var header_lines = variable_global_exists("debug_log_header_lines") ? global.debug_log_header_lines : [];
        var beat_lines2 = variable_global_exists("canonical_beats") ? global.canonical_beats : [];
        var footer_lines = variable_global_exists("debug_only_lines") ? global.debug_only_lines : [];

        var f = file_text_open_write(global.debug_log_path);

        for (var h = 0; h < array_length(header_lines); h++) {
            file_text_write_string(f, header_lines[h] + "\n");
        }
        for (var b = 0; b < array_length(beat_lines2); b++) {
            file_text_write_string(f, beat_lines2[b] + "\n");
        }
        for (var d = 0; d < array_length(footer_lines); d++) {
            file_text_write_string(f, footer_lines[d] + "\n");
        }

        file_text_close(f);
    }

    global.debug_log_pending = "";
    global.debug_log_pending_lines = 0;
    global.beat_log_pending = "";
    global.beat_log_pending_lines = 0;
}
