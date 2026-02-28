if (!global.debug_enabled || (!global.debug_output_enabled && !global.tuner_active)) exit;

var margin = 560;
var _x = margin;
var _y = margin;

var header =
    "DEBUG CONSOLE  |  Seed: " + string(global.debug_seed) +
    "  |  Short: " + string(global.debug_short_mode) +
    "  |  Beats: " + string(global.debug_beats_emitted) + "/" + string(global.debug_max_beats) +
    "\nKeys: R=rerun  N=next seed  S=toggle short  C=clear  V=copy run log  F7=randomize seed" +
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
    var ow = 520;
    var oh = 420;

    draw_set_alpha(0.78);
    draw_set_color(c_black);
    draw_rectangle(ox, oy, ox + ow, oy + oh, false);
    draw_set_alpha(1);
    draw_set_color(c_white);

    draw_text(ox + 12, oy + 10, "FINE TUNER (F2)  |  Up/Down select  Left/Right adjust  Shift+Left/Right big step");

    var row_y = oy + 36;
    var bar_x = ox + 280;
    var bar_w = 180;
    var bar_h = 10;

    for (var si = 0; si < array_length(tuner_sliders); si++) {
        var row = tuner_sliders[si];
        var val = variable_struct_get(global.tuning, row.key);
        var norm = (val - row.min) / max(0.0001, (row.max - row.min));
        norm = clamp(norm, 0, 1);

        var sel = (si == slider_index) ? "> " : "  ";
        var val_txt = (row.decimals > 0) ? string_format(val, 1, row.decimals) : string(round(val));
        draw_text(ox + 12, row_y, sel + row.label + ": " + val_txt + " [" + string(row.min) + ".." + string(row.max) + "]");

        draw_set_color(c_dkgray);
        draw_rectangle(bar_x, row_y + 4, bar_x + bar_w, row_y + 4 + bar_h, false);
        draw_set_color((si == slider_index) ? c_lime : c_aqua);
        draw_rectangle(bar_x, row_y + 4, bar_x + floor(bar_w * norm), row_y + 4 + bar_h, false);
        draw_set_color(c_white);

        row_y += 24;
    }

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
}
