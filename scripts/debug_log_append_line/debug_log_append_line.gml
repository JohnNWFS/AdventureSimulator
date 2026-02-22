function debug_log_append_line(line)
{
    if (!variable_global_exists("debug_log_path")) return;
    if (!variable_global_exists("debug_log_pending")) global.debug_log_pending = "";
    if (!variable_global_exists("debug_log_pending_lines")) global.debug_log_pending_lines = 0;

    // Batch to reduce file I/O
    global.debug_log_pending += line + "\n";
    global.debug_log_pending_lines += 1;

    if (!variable_global_exists("debug_log_text")) global.debug_log_text = "";
    global.debug_log_text += line + "\n";

    // Flush every 25 lines (tweak as you like)
    if (global.debug_log_pending_lines >= 25) debug_log_flush();
}
