/// obj_sim_controller :: Draw GUI
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var gui_x = 16;
var gui_y = 16;

// Header
var header =
    "Seed: " + string(sim.seed) +
    " | Beat: " + string(sim.beat) + "/" + string(sim.beats_target) +
    " | Zone: " + string(sim.zone) +
    " | Tension: " + string(sim.tension) +
    " | Gold: " + string(sim.gold_total) +
    (sim.finished ? " | FINISHED" : (auto_run ? " | RUNNING" : " | PAUSED"));

draw_text(gui_x, gui_y, header);
gui_y += 22;

// Tiny blockout animation preview.
if (global.debug_blockout_playback) {
    var panel_x = display_get_gui_width() - 440;
    var panel_y = 14;
    var panel_w = 420;
    var panel_h = 190;

    var now_ms = current_time;
    var p = (now_ms - blockout_shot.start_ms) / max(1, blockout_shot.duration_ms);
    if (p < 0) p = 0;
    if (p > 1) p = 1;

    var bg_col = make_color_rgb(28, 32, 38);
    if (blockout_shot.lane == "overlay") bg_col = make_color_rgb(35, 28, 44);
    if (blockout_shot.lane == "ui") bg_col = make_color_rgb(22, 36, 28);

    draw_set_alpha(0.95);
    draw_set_color(bg_col);
    draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);

    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);

    var center_y = panel_y + panel_h * 0.62;
    var hero_x = panel_x + 78 + 50 * p;
    var enemy_x = panel_x + panel_w - 108 - 70 * p;

    // Role blocks (party left)
    draw_set_color(make_color_rgb(100, 180, 255));
    draw_rectangle(hero_x - 14, center_y - 54, hero_x + 14, center_y - 12, false);
    draw_set_color(make_color_rgb(132, 212, 148));
    draw_rectangle(hero_x + 22, center_y - 50, hero_x + 46, center_y - 16, false);

    // Encounter block (enemy right)
    draw_set_color(make_color_rgb(236, 102, 106));
    draw_rectangle(enemy_x - 16, center_y - 58, enemy_x + 16, center_y - 8, true);

    if (blockout_shot.beat_tag == "LOOT_FOUND") {
        draw_set_color(make_color_rgb(250, 210, 98));
        draw_rectangle(panel_x + panel_w * 0.50 - 10, center_y - 24, panel_x + panel_w * 0.50 + 10, center_y - 4, false);
    }

    draw_set_color(c_white);
    draw_text(panel_x + 10, panel_y + 8,
        "BLOCKOUT PREVIEW  [B] toggle\n" +
        "Tag: " + blockout_shot.beat_tag +
        " | Anim: " + blockout_shot.anim_id +
        " | Lane: " + blockout_shot.lane +
        "\nProgress: " + string_format(p * 100, 3, 0) + "%"
    );
}

// Party HUD (simple)
for (var i = 0; i < array_length(sim.party); i++) {
    var p = sim.party[i];
	var line = p.role + " " + p.name +
    "  HP " + string(p.hp) + "/" + string(p.max_hp) +
    "  MP " + string(p.mp) + "/" + string(p.max_mp) +
    "  ATK " + string(p.atk) + " DEF " + string(p.def) +
    "  Wounds " + string(p.wounds);
	
	var eq = (variable_struct_exists(p, "equip") && is_struct(p.equip))
    ? p.equip
    : { weapon: undefined, armor: undefined, trinket: undefined };
	
	line += "  W:" + sim_item_name(eq.weapon) +
	        "  A:" + sim_item_name(eq.armor) +
	        "  T:" + sim_item_name(eq.trinket);

    draw_text(gui_x, gui_y, line);
    gui_y += 18;
}

gui_y += 8;
draw_text(gui_x, gui_y,
    "Controls: ENTER=new seed | R=replay seed | T=toggle short | V=toggle very short | Q=4-seed short test | SPACE=toggle run | N=step (paused) | B=blockout preview"
);
gui_y += 22;

// Log (last N lines)
var start = max(0, array_length(sim.log) - ui_max_lines);
for (var j = start; j < array_length(sim.log); j++) {
    draw_text(gui_x, gui_y, sim.log[j]);
    gui_y += 16;
}
