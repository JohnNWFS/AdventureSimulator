function debug_log_start_file(seed)
{
    var dir = "logs";
    if (!directory_exists(dir)) directory_create(dir);

	var ts =
	    string(date_get_year(date_current_datetime())) +
	    _zero_pad(date_get_month(date_current_datetime()), 2) +
	    _zero_pad(date_get_day(date_current_datetime()), 2) + "_" +
	    _zero_pad(date_get_hour(date_current_datetime()), 2) +
	    _zero_pad(date_get_minute(date_current_datetime()), 2) +
	    _zero_pad(date_get_second(date_current_datetime()), 2);

    global.beat_log_path = dir + "/run_" + ts + "_seed_" + string(seed) + ".txt";
    global.debug_log_path = dir + "/run_" + ts + "_seed_" + string(seed) + ".debug.txt";
    global.debug_log_pending = "";
    global.debug_log_pending_lines = 0;
    global.beat_log_pending = "";
    global.beat_log_pending_lines = 0;
    global.debug_log_text = "";
    global.beat_log_text = "";
    global.canonical_beats = [];
    global.debug_only_lines = [];
    global.debug_log_header_lines = ["=== RUN START seed=" + string(seed) + " ==="];

    // Create/normalize files right now (UTF-8 text, no BOM for beat output).
    var f_beat = file_text_open_write(global.beat_log_path);
    file_text_close(f_beat);
    var f = file_text_open_write(global.debug_log_path);
    file_text_close(f);
    debug_log_flush();

    show_debug_message("BEAT_LOG_FILE=" + game_save_id + global.beat_log_path);
    show_debug_message("DEBUG_LOG_FILE=" + game_save_id + global.debug_log_path);
}



