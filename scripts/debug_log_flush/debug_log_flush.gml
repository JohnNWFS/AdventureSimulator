function debug_log_flush()
{
    if (!variable_global_exists("debug_log_path")) return;
    if (!variable_global_exists("debug_log_pending")) return;
    if (global.debug_log_pending == "") return;

    var f = file_text_open_append(global.debug_log_path);
    file_text_write_string(f, global.debug_log_pending);
    file_text_close(f);

    global.debug_log_pending = "";
    global.debug_log_pending_lines = 0;
}

