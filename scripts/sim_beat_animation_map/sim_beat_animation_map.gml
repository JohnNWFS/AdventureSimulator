function sim_beat_animation_map_table()
{
    if (!variable_global_exists("sim_beat_anim_map")) {
        global.sim_beat_anim_map = {
            EPISODE_HOOK:   { anim_id: "episode_hook", lane: "scene" },
            COMPLICATION:   { anim_id: "complication", lane: "scene" },
            BEAT_SOURCE:    { anim_id: "beat_source", lane: "overlay" },
            ENCOUNTER:      { anim_id: "encounter_start", lane: "scene" },
            ENCOUNTER_SHIFT:{ anim_id: "encounter_shift", lane: "overlay" },
            COMBAT_EXCHANGE:{ anim_id: "combat_exchange", lane: "scene" },
            BOSS_SPAWN:     { anim_id: "boss_spawn", lane: "scene" },
            BOSS_FIGHT:     { anim_id: "boss_fight", lane: "scene" },
            CHEST_OPEN:     { anim_id: "chest_open", lane: "scene" },
            CHEST_TRAP:     { anim_id: "chest_trap", lane: "overlay" },
            CHEST_GOLD:     { anim_id: "chest_gold", lane: "ui" },
            CHEST_RARE:     { anim_id: "chest_rare", lane: "ui" },
            CHEST_ITEM:     { anim_id: "chest_item", lane: "ui" },
            LOOT_FOUND:     { anim_id: "loot_found", lane: "ui" },
            MERCHANT_OFFER: { anim_id: "merchant_offer", lane: "scene" },
            MERCHANT_BUY:   { anim_id: "merchant_buy", lane: "ui" },
            MERCHANT_DECLINE:{ anim_id: "merchant_decline", lane: "ui" },
            MERCHANT_BROWSE:{ anim_id: "merchant_browse", lane: "overlay" },
            DIRECTOR_REROUTE:{ anim_id: "director_reroute", lane: "overlay" },
            RETREAT_CALL:   { anim_id: "retreat_call", lane: "overlay" },
            DOWNED:         { anim_id: "party_downed", lane: "overlay" },
            DEATH:          { anim_id: "party_death", lane: "overlay" },
            ADVENTURE_START:{ anim_id: "adventure_start", lane: "scene" },
            PARTY_ROSTER:   { anim_id: "party_roster_pose", lane: "overlay" },
            CITY_ARRIVE:    { anim_id: "city_arrive", lane: "scene" },
            CITY_DEPART:    { anim_id: "city_depart", lane: "scene" },
            CITY_REPUTATION_UPDATE:{ anim_id: "city_reputation", lane: "ui" },
            INJURY_LINGERS: { anim_id: "injury_lingers", lane: "overlay" },
            INJURY_RECOVERED:{ anim_id: "injury_recovered", lane: "overlay" },
            VOLUNTARY_RETIREMENT:{ anim_id: "retire_decision", lane: "scene" },
            NEW_RECRUIT:    { anim_id: "recruit_join", lane: "scene" },
            FACTION_EVENT:  { anim_id: "faction_event", lane: "scene" },
            CITY_EFFECT_APPLIED:{ anim_id: "city_effect", lane: "ui" },
            DUNGEON_ENTER:  { anim_id: "dungeon_enter", lane: "scene" }
        };
    }

    return global.sim_beat_anim_map;
}

function sim_beat_animation_map_get(tag)
{
    var map = sim_beat_animation_map_table();
    var key = string_upper(string(tag));

    if (variable_struct_exists(map, key)) {
        return variable_struct_get(map, key);
    }

    return { anim_id: "unknown_beat", lane: "overlay" };
}
