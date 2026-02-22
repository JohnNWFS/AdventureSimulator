function debug_log_flush()
{
    if (variable_global_exists("debug_log_path") && variable_global_exists("debug_log_pending") && global.debug_log_pending != "") {
        var f = file_text_open_append(global.debug_log_path);
        file_text_write_string(f, global.debug_log_pending);
        file_text_close(f);

        global.debug_log_pending = "";
        global.debug_log_pending_lines = 0;
    }

    if (variable_global_exists("beat_log_path") && variable_global_exists("beat_log_pending") && global.beat_log_pending != "") {
        var f_beat = file_text_open_append(global.beat_log_path);
        file_text_write_string(f_beat, global.beat_log_pending);
        file_text_close(f_beat);

        global.beat_log_pending = "";
        global.beat_log_pending_lines = 0;
    }
}
