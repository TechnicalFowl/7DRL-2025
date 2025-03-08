module dg;

struct GameStats
{
    double turns;
    int damage_dealt;
    int damage_taken;
    int enemies_killed;
    int items_picked_up;
    int ore_smelted;
    int ore_mined;
    int gold_spent;
    int gold_picked_up;
    int items_smithed;
    int logs_chopped;
    int runes_consumed;
    int doors_opened;
    int chests_opened;
    int crates_looted;
    double time_spent_rooted;
    double distance_traveled;
    int potions_drank;
    int rations_eaten;
    int experience_gained;
    int levels_gained;
    double time_spent_waiting;
}
GameStats g_stats;

fn void reset_stats()
{
    g_stats.turns = 0;
    g_stats.damage_dealt = 0;
    g_stats.damage_taken = 0;
    g_stats.enemies_killed = 0;
    g_stats.items_picked_up = 0;
    g_stats.ore_smelted = 0;
    g_stats.ore_mined = 0;
    g_stats.gold_spent = 0;
    g_stats.gold_picked_up = 0;
    g_stats.items_smithed = 0;
    g_stats.logs_chopped = 0;
    g_stats.runes_consumed = 0;
    g_stats.doors_opened = 0;
    g_stats.chests_opened = 0;
    g_stats.crates_looted = 0;
    g_stats.time_spent_rooted = 0;
    g_stats.distance_traveled = 0;
    g_stats.potions_drank = 0;
    g_stats.rations_eaten = 0;
    g_stats.experience_gained = 0;
    g_stats.levels_gained = 0;
    g_stats.time_spent_waiting = 0;
}