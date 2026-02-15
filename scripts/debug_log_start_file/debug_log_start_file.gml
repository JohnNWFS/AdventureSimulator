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

    global.debug_log_path = dir + "/run_" + ts + "_seed_" + string(seed) + ".txt";
    global.debug_log_pending = "";
    global.debug_log_pending_lines = 0;

    // HARD GUARANTEE: create the file right now + print where it is
    var f = file_text_open_append(global.debug_log_path);
    file_text_write_string(f, "=== RUN START seed=" + string(seed) + " ===\n");
    file_text_close(f);

    show_debug_message("LOG_FILE=" + game_save_id + global.debug_log_path);
}





