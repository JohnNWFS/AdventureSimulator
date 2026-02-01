function sim_adjust_resolve(sim, p, delta, reason_tag) {
    // delta negative reduces resolve
    if (!variable_struct_exists(p, "resolve")) return;

    var before = p.resolve;
    p.resolve = clamp(p.resolve + delta, 0, 100);

    // Light logging only when it matters (keeps the log from becoming a spreadsheet)
    if (delta < 0 && (p.resolve <= 25) && (!p.cracking_flag)) {
        p.cracking_flag = true;
        sim_log_tag(sim, "CRACKING",
            "🫠 " + p.name + " looks shaken (" + string(before) + "→" + string(p.resolve) + ")."
        );
    }

    if (p.resolve <= 10 && (!p.retire_notice)) {
        p.retire_notice = true;
        sim_log_tag(sim, "RETIRE_NOTICE",
            "🏳 " + p.name + " mutters: 'After this… I'm done.'"
        );
    }

    // Optional debug tag hook if you ever want it:
    // sim_log_tag(sim, reason_tag, "Resolve " + string(before) + "→" + string(p.resolve));
}
