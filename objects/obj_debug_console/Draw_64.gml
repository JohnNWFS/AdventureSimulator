if (!global.debug_enabled || (!global.debug_output_enabled && !global.tuner_active)) exit;

var margin = 560;
var _x = margin;
var _y = margin;

var header =
    "DEBUG CONSOLE  |  Seed: " + string(global.debug_seed) +
    "  |  Short: " + string(global.debug_short_mode) +
    "  |  VeryShort: " + string(global.debug_very_short_mode) +
    "  |  Beats: " + string(global.debug_beats_emitted) + "/" + string(global.debug_max_beats) +
    "\nKeys: R=rerun  N=next seed  S=toggle short  F8=toggle very short  C=clear  V=copy run log  F7=randomize seed" +
    "\nF9=run debug find batch (searches debug_find_string across repeated seeded runs)  F10=macro runs  F11=toggle debug output";

draw_set_alpha(1);
draw_text(_x, _y, header);

_y += 48;

// Draw last lines
var lines = global.debug_lines;
var count = array_length(lines);

// How many lines fit? Keep it simple: fixed max visible
var max_visible = 24;
var start = max(0, count - max_visible);

for (var i = start; i < count; i++) {
    draw_text(_x, _y, lines[i]);
    _y += 16;
}


if (global.tuner_active) {
    var ox = 20;
    var oy = 80;
    var row_y_start = oy + 36;
    var row_count = array_length(tuner_sliders);
    var stats_start = row_y_start + (row_count * 24) + 8;
    var stats_end = stats_start + 20 + (9 * 16);

    var bg_top = oy - 10;
    var bg_bottom = stats_end + 26;
    var gui_w = display_get_gui_width();

    draw_set_alpha(0.82);
    draw_set_color(c_black);
    draw_rectangle(0, bg_top, gui_w, bg_bottom, false);
    draw_set_alpha(1);
    draw_set_color(c_white);

    draw_text(ox + 12, oy + 10, "FINE TUNER (F2)  |  Up/Down select  Left/Right adjust  Shift+Left/Right big step  |  Hover row for help or click [i]");

    var row_y = row_y_start;
    var bar_x = ox + 280;
    var bar_w = 180;
    var bar_h = 10;
    var btn_x = ox + 12;
    var label_x = ox + 40;

    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    var hover_help_key = "";

    for (var si = 0; si < row_count; si++) {
        var row = tuner_sliders[si];
        var val = variable_struct_get(global.tuning, row.key);
        var norm = (val - row.min) / max(0.0001, (row.max - row.min));
        norm = clamp(norm, 0, 1);

        var row_top = row_y;
        var row_bottom = row_y + 16;
        var btn_w = 20;
        var btn_h = 16;
        var row_left = label_x;
        var row_right = bar_x + bar_w;
        var in_row = (mx >= row_left && mx <= row_right && my >= row_top && my <= row_bottom);
        var in_btn = (mx >= btn_x && mx <= btn_x + btn_w && my >= row_top && my <= row_top + btn_h);

        if (in_row || in_btn) hover_help_key = row.key;

        draw_set_color(in_btn ? c_yellow : c_ltgray);
        draw_rectangle(btn_x, row_top, btn_x + btn_w, row_top + btn_h, false);
        draw_set_color(c_black);
        draw_text(btn_x + 6, row_top + 1, "i");
        draw_set_color(c_white);

        var sel = (si == slider_index) ? "> " : "  ";
        var val_txt = (row.decimals > 0) ? string_format(val, 1, row.decimals) : string(round(val));
        draw_text(label_x, row_y, sel + row.label + ": " + val_txt + " [" + string(row.min) + ".." + string(row.max) + "]");

        draw_set_color(c_dkgray);
        draw_rectangle(bar_x, row_y + 4, bar_x + bar_w, row_y + 4 + bar_h, false);
        draw_set_color((si == slider_index) ? c_lime : c_aqua);
        draw_rectangle(bar_x, row_y + 4, bar_x + floor(bar_w * norm), row_y + 4 + bar_h, false);
        draw_set_color(c_white);

        row_y += 24;
    }

    tuner_hover_help_key = hover_help_key;

    var eps = max(1, global.tuner_session.episodes);
    var stats_y = row_y + 8;
    draw_text(ox + 12, stats_y, "Session aggregates");
    stats_y += 20;
    draw_text(ox + 12, stats_y, "Episodes: " + string(global.tuner_session.episodes));
    stats_y += 16;
    draw_text(ox + 12, stats_y, "Avg combats: " + string_format(global.tuner_session.sum_combats / eps, 1, 2));
    stats_y += 16;
    draw_text(ox + 12, stats_y, "Avg chests opened: " + string_format(global.tuner_session.sum_chests / eps, 1, 2));
    stats_y += 16;
    draw_text(ox + 12, stats_y, "Avg merchants seen: " + string_format(global.tuner_session.sum_merchants / eps, 1, 2));
    stats_y += 16;
    draw_text(ox + 12, stats_y, "Avg rares found: " + string_format(global.tuner_session.sum_rares / eps, 1, 2));
    stats_y += 16;
    draw_text(ox + 12, stats_y, "Avg party deaths: " + string_format(global.tuner_session.sum_deaths / eps, 1, 2));
    stats_y += 16;
    draw_text(ox + 12, stats_y, "Avg retirements: " + string_format(global.tuner_session.sum_retirements / eps, 1, 2));
    stats_y += 16;
    draw_text(ox + 12, stats_y, "Avg gold: " + string_format(global.tuner_session.sum_gold / eps, 1, 2));
    stats_y += 16;
    draw_text(ox + 12, stats_y, "Boss defeat rate: " + string_format(global.tuner_session.boss_defeated_count / eps, 1, 2));

    var help_key = (tuner_hover_help_key != "") ? tuner_hover_help_key : tuner_selected_help_key;
    if (help_key != "" && variable_struct_exists(tuner_help, help_key)) {
        var help_text = help_key + "\n" + variable_struct_get(tuner_help, help_key);
        var help_x = ox + 560;
        var help_y = oy + 36;
        var help_w = max(340, gui_w - help_x - 20);
        var help_h = 210;

        if (tuner_selected_help_key != "" && tuner_hover_help_key == "") {
            help_y = stats_end - help_h;
        }

        draw_set_alpha(0.9);
        draw_set_color(c_black);
        draw_rectangle(help_x, help_y, help_x + help_w, help_y + help_h, false);
        draw_set_alpha(1);
        draw_set_color(c_yellow);
        draw_text(help_x + 12, help_y + 10, "TUNER HELP");
        draw_set_color(c_white);
        draw_text_ext(help_x + 12, help_y + 30, help_text, 16, help_w - 24);
    }
}
