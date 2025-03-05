module dg;

import std::collections::list;
import std::collections::map;
import std::io;
import std::math::random;

import raylib5::rl;

random::Pcg32Random g_rng;

int font_size = 16;
Font* sprite_font;
Font* textmode_font;
Font* text_font;

bool textmode;

struct LogMessage
{
    String message;
    rl::Color color;
}
List(<LogMessage>) log_messages;

int map_zoom = 3;
VirtualTerminal map_term;
VirtualTerminal ui_term;

const int FLOOR_SIZE = 4;

Zone* g_zone;
bool want_exit_floor;

bool show_visibility;

DungeonFloor* current_floor;

bool devmode;
bool devmode_immortal;

double elapsed_time;

enum GameState
{
    PLAYING,
    MAIN_MENU,
    GAME_OVER,
    VICTORY,
}
GameState game_state;

struct Settings
{
    double hover_tooltip_delay;
    bool scroll_to_wait;
}
Settings g_settings;

fn void load_default_settings()
{
    g_settings.hover_tooltip_delay = 1.0;
    g_settings.scroll_to_wait = true;

    if (devmode) devmode_immortal = true;
}

fn void log(String message, rl::Color color = colors::WHITE)
{
    log_messages.push({message, color});
}

struct GeneratorData
{
    ulong seed;
    int depth;

    Player* old_player;
}

fn void GeneratorData.generate(&self, Zone* zone)
{
    random::Pcg32Random rng;
    //random::seed_entropy(&rng);
    random::seed(&rng, self.seed);

    zone.name = string::new_format("Floor %d", self.depth);

    if (current_floor)
    {
        current_floor.free();
        mem::free(current_floor);
    }
    current_floor = mem::new(DungeonFloor);
    current_floor.new_init(self.depth);

    for (int y = 0; y < FLOOR_SIZE; ++y)
    {
        for (int x = 0; x < FLOOR_SIZE; ++x)
        {
            Room* room = mem::new(Room);
            room.new_init({x * 17, y * 17}, {16, 16});
            current_floor.rooms.set({x, y}, room);
        }
    }

    HashMap(<IVec2, bool>) placed;
    HashMap(<IVec2, bool>) adjacent;
    List(<IVec2>) creation_order;
    List(<IVec2>) farthest;
    placed.temp_init();
    adjacent.temp_init();
    creation_order.temp_init();
    farthest.temp_init();
    int farthest_distance = 0;

    IVec2 start = {random::next_in_range(&rng, 0, FLOOR_SIZE - 1), random::next_in_range(&rng, 0, FLOOR_SIZE - 1)};
    placed.set(start, true);
    if (start.x < FLOOR_SIZE - 1) adjacent.set({ start.x + 1, start.y }, true);
    if (start.x > 0) adjacent.set({ start.x - 1, start.y }, true);
    if (start.y < FLOOR_SIZE - 1) adjacent.set({ start.x, start.y + 1 }, true);
    if (start.y > 0) adjacent.set({ start.x, start.y - 1 }, true);

    while (!adjacent.is_empty())
    {
        IVec2[] keys = adjacent.tcopy_keys();
        assert(keys.len > 0, "No adjacent rooms");
        IVec2 next = keys[random::next_in_range(&rng, 0, (int) keys.len - 1)];
        List(<Direction>) neighbors;
        if (next.x > 0 && placed.get({next.x - 1, next.y}) ?? false) neighbors.push(WEST);
        if (next.x < FLOOR_SIZE - 1 && placed.get({next.x + 1, next.y}) ?? false) neighbors.push(EAST);
        if (next.y > 0 && placed.get({next.x, next.y - 1}) ?? false) neighbors.push(NORTH);
        if (next.y < FLOOR_SIZE - 1 && placed.get({next.x, next.y + 1}) ?? false) neighbors.push(SOUTH);
        assert(neighbors.len() > 0, "No neighbors for room");

        Direction neighbor = neighbors[random::next_in_range(&rng, 0, (int) neighbors.len() - 1)];
        
        Room* next_room = current_floor.rooms.get(next)!!;
        Room* neighbor_room = current_floor.rooms.get(next + neighbor.dir)!!;
        next_room.distance_from_start = neighbor_room.distance_from_start + 1;
        creation_order.push(next);
        
        if (next_room.distance_from_start > farthest_distance)
        {
            farthest_distance = next_room.distance_from_start;
            farthest.clear();
            farthest.push(next);
        }
        else if (next_room.distance_from_start == farthest_distance)
        {
            farthest.push(next);
        }

        Door* door = &next_room.doors[neighbor.ordinal - 1];
        door.direction = neighbor;
        door.type = UNLOCKED;

        Door* ndoor = &neighbor_room.doors[FLIP[neighbor.ordinal].ordinal - 1];
        ndoor.direction = FLIP[neighbor.ordinal];
        ndoor.type = UNLOCKED;

        placed.set(next, true);
        adjacent.remove(next);

        if (next.x > 0 && !(placed.get({next.x - 1, next.y}) ?? false)) adjacent.set({next.x - 1, next.y}, true);
        if (next.x < FLOOR_SIZE - 1 && !(placed.get({next.x + 1, next.y}) ?? false)) adjacent.set({next.x + 1, next.y}, true);
        if (next.y > 0 && !(placed.get({next.x, next.y - 1}) ?? false)) adjacent.set({next.x, next.y - 1}, true);
        if (next.y < FLOOR_SIZE - 1 && !(placed.get({next.x, next.y + 1}) ?? false)) adjacent.set({next.x, next.y + 1}, true);
    }

    Room* start_room = current_floor.rooms.get(start)!!;
    start_room.type = STARTING;

    assert(farthest.len() > 0, "No farthest room found");
    IVec2 boss_pos = farthest[random::next_in_range(&rng, 0, (int) farthest.len() - 1)];
    Room* boss_room = current_floor.rooms.get(boss_pos)!!;
    boss_room.type = BOSS;
    
    {
        if (boss_room.doors[Direction.WEST.ordinal - 1].type != WALL)
        {
            boss_room.doors[Direction.WEST.ordinal - 1].type = BOSS;
            current_floor.rooms.get({boss_pos.x - 1, boss_pos.y})!!.doors[Direction.EAST.ordinal - 1].type = BOSS;
        }
        if (boss_room.doors[Direction.EAST.ordinal - 1].type != WALL)
        {
            boss_room.doors[Direction.EAST.ordinal - 1].type = BOSS;
            current_floor.rooms.get({boss_pos.x + 1, boss_pos.y})!!.doors[Direction.WEST.ordinal - 1].type = BOSS;
        }
        if (boss_room.doors[Direction.NORTH.ordinal - 1].type != WALL)
        {
            boss_room.doors[Direction.NORTH.ordinal - 1].type = BOSS;
            current_floor.rooms.get({boss_pos.x, boss_pos.y - 1})!!.doors[Direction.SOUTH.ordinal - 1].type = BOSS;
        }
        if (boss_room.doors[Direction.SOUTH.ordinal - 1].type != WALL)
        {
            boss_room.doors[Direction.SOUTH.ordinal - 1].type = BOSS;
            current_floor.rooms.get({boss_pos.x, boss_pos.y + 1})!!.doors[Direction.NORTH.ordinal - 1].type = BOSS;
        }
    }
    
    OSN_Context* ctx;
    open_simplex_noise((long) rng.next_long(), &ctx);

    float noise_scale = 12;
    
    for (int y = 0; y < FLOOR_SIZE; ++y)
    {
        for (int x = 0; x < FLOOR_SIZE; ++x)
        {
            if (!(placed.get({x, y}) ?? false)) continue;
            Room* room = current_floor.rooms.get({x, y})!!;
            IVec2 pos = room.position;
            IVec2 size = room.size;
            for (int ry = 0; ry < size.y; ++ry)
            {
                for (int rx = 0; rx < size.x; ++rx)
                {
                    if (rx == 0 && ry == 0)
                    {
                        zone.set_terrain(pos.x+ rx, pos.y + ry, TERR_WALL_NW);
                    }
                    else if (rx == 0 && ry == size.y - 1)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, TERR_WALL_SW);
                    }
                    else if (rx == size.x - 1 && ry == 0)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, TERR_WALL_NE);
                    }
                    else if (rx == size.x - 1 && ry == size.y - 1)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, TERR_WALL_SE);
                    }
                    else if (rx == 0)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, TERR_WALL_WEST);
                    }
                    else if (rx == size.x - 1)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, TERR_WALL_EAST);
                    }
                    else if (ry == 0)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, TERR_WALL_NORTH);
                    }
                    else if (ry == size.y - 1)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, TERR_WALL_SOUTH);
                    }
                    else
                    {
                        double v0 = open_simplex_noise2(ctx, (double) (pos.x + rx) / noise_scale, (double) (pos.y + ry) / noise_scale);
                        double v1 = open_simplex_noise2(ctx, (double) (pos.x + rx) / noise_scale * 2, (double) (pos.y + ry) / noise_scale * 2);
                        double v2 = open_simplex_noise2(ctx, (double) (pos.x + rx) / noise_scale * 4, (double) (pos.y + ry) / noise_scale * 4);

                        double fval = v0 * (4.0 / 7.0) + v1 * (2.0 / 7.0) + v2 * (1.0 / 7.0);

                        TerrainType floor;
                        if (fval < -0.3)
                        {
                            floor = TERR_CLEAN_STONE;
                        }
                        else if (fval < 0.0)
                        {
                            floor = TERR_STONE;
                        }
                        else if (fval < 0.2)
                        {
                            floor = TERR_ROUGH_STONE;
                        }
                        else
                        {
                            floor = TERR_DIRT;
                        }
                        zone.set_terrain(pos.x + rx, pos.y + ry, floor);
                    }
                }
            }
            room.generate(current_floor, zone, &rng);
        }
    }

    int boss_depth = boss_room.distance_from_start;
    int locked_doors = random::next_in_range(&rng, 1, 3);
    int attempts = 0;
    while (locked_doors > 0 && attempts < 100)
    {
        attempts++;
        IVec2 rpos = {random::next_in_range(&rng, 0, FLOOR_SIZE - 1), random::next_in_range(&rng, 0, FLOOR_SIZE - 1)};
        Room* room = current_floor.rooms.get(rpos)!!;
        if (room.type == BOSS || room.type == STARTING) continue;

        int idx = (int) creation_order.index_of(rpos) ?? 0;
        if (idx <= 0) continue;

        List(<Direction>) neighbors;
        neighbors.temp_init();

        for (int i = 1; i <= 4; ++i)
        {
            if (room.doors[i - 1].type == UNLOCKED)
            {
                neighbors.push(Direction.from_ordinal(i));
            }
        }

        if (neighbors.is_empty()) continue;

        Direction to_lock = neighbors[random::next_in_range(&rng, 0, (int) neighbors.len() - 1)];
        room.doors[to_lock.ordinal - 1].type = LOCKED;
        IVec2 pos = room.position;
        
        switch (to_lock)
        {
        case NORTH:
            lock_door(zone, {pos.x + 7, pos.y});
        case EAST:
            lock_door(zone, {pos.x + 15, pos.y + 7});
        case SOUTH:
            lock_door(zone, {pos.x + 7, pos.y + 15});
        case WEST:
            lock_door(zone, {pos.x, pos.y + 7});
        default:
            unreachable();
        }

        IVec2 key_room = creation_order[random::next_in_range(&rng, 0, idx - 1)];
        Room* key = current_floor.rooms.get(key_room)!!;
        IVec2 p = get_random_pos(&rng, key.position + {6, 6}, {4, 4});
        p = zone.find_nearest_empty(p);
        zone.drop_item(...p, {KEY, 1, 0});

        locked_doors--;
    }
    assert(locked_doors == 0, "Could not place all locked doors");

    Player* pl = mem::new(Player);
    pl.new_init(zone, "Player", {start.x * 17 + 7, start.y * 17 + 8});

    if (self.old_player)
    {
        pl.health = self.old_player.health;
        pl.inventory = self.old_player.inventory;
        pl.equipment = self.old_player.equipment;
        pl.level = self.old_player.level;
        pl.experience = self.old_player.experience;
    }

    zone.add_player(pl);
    pl.explore(start_room.position, {16, 16});
}

fn void load_zone(ZoneDescription desc)
{
    Zone* old_zone = g_zone;
    g_zone = mem::new(Zone);
    g_zone.new_init(desc);
    if (old_zone)
    {
        old_zone.free();
        mem::free(old_zone);
    }
}

fn void load_floor(int depth)
{
    ZoneDescription initial_zone;
    initial_zone.new_init("dungeon", 17 * FLOOR_SIZE, 17 * FLOOR_SIZE);
    GeneratorData generator = { 165361613 * ((ulong) depth + 1), depth, g_zone ? (Player*) g_zone.player : null };
    initial_zone.generator = (ZoneGenerator) &GeneratorData.generate;
    initial_zone.generator_data = &generator;

    log("You descend further into the depths of Daemonheim...", colors::RED);

    load_zone(initial_zone);

    inv_action = NO_ACTION;
}

fn int main(String[] args)
{
    //waitForDebugger();
    initExceptionHandler();

    rl::traceLog(rl::TraceLogLevel.INFO, "C3RL: Initializing...");

    foreach (s: args)
    {
        if (s == "-devmode")
        {
            devmode = true;
            rl::traceLog(rl::TraceLogLevel.INFO, "C3RL: Developer mode enabled");
        }
    }

    load_default_settings();

    random::seed_entropy(&g_rng);
    generate_whole_dungeon_stuff(&g_rng);

    int term_width = 80;
    int term_height = 50;

    rl::initWindow(term_width * font_size, term_height * font_size, "The Depths of Daemonheim - 7DRL 2025");
    rl::setTargetFPS(60);
    rl::setExitKey(0);
    rl::setWindowState(rl::FLAG_WINDOW_RESIZABLE);
    rl::setWindowMinSize(term_width * font_size, term_height * font_size);

    init_inputs();

    set_font_directory("resources");

    Font*! sprites = get_font("sprites", { font_size, font_size });
    if (catch sprites)
    {
        return -1;
    }
    sprite_font = sprites;
    Font*! font = get_font("cp437", { font_size, font_size });
    if (catch font)
    {
        return -1;
    }
    textmode_font = font;
    Font*! hfont = get_font("cp437", { font_size / 2, font_size });
    if (catch hfont)
    {
        return -1;
    }
    text_font = hfont;

    textmode = false;
    map_term.new_init(term_width / map_zoom, term_height / map_zoom, textmode ? textmode_font : sprite_font);
    ui_term.new_init(term_width * 2, term_height, text_font);

    g_items.new_init();
    g_mobs.new_init();

    ZoneDescription initial_zone;
    initial_zone.new_init("tutorial", 17 * FLOOR_SIZE, 17 * FLOOR_SIZE);
    GeneratorData generator = { (ulong) g_rng.next_long(), 0, null };
    initial_zone.generator = (ZoneGenerator) &GeneratorData.generate;
    initial_zone.generator_data = &generator;

    load_zone(initial_zone);
    
    gui::gui_data.new_init();
    init_ui();

    rl::traceLog(rl::TraceLogLevel.INFO, "C3RL: Starting game loop...");
    
    game_state = PLAYING;

    log("You descend into the depths of Daemonheim...", colors::RED);

    while (!rl::windowShouldClose())
    {
        @pool()
        {
            if (rl::isWindowResized())
            {
                int new_width = rl::getScreenWidth();
                int new_height = rl::getScreenHeight();
                map_term.on_resize((new_width / font_size) / map_zoom, (new_height / font_size) / map_zoom);
                ui_term.on_resize((new_width / font_size) * 2, (new_height / font_size));
            }
            
            rl::beginDrawing();
            rl::clearBackground(colors::BLACK);

            update_inputs();

            switch (game_state)
            {
            case PLAYING:
                if (!gui::want_key_input())
                {
                    if (is_key_pressed(TOGGLE_TEXTMODE, false))
                    {
                        textmode = !textmode;
                    }
                    
                    if (is_key_pressed(TOGGLE_ZOOM, false))
                    {
                        map_zoom = map_zoom == 1 ? 3 : 1;
                        
                        int new_width = rl::getScreenWidth();
                        int new_height = rl::getScreenHeight();
                        map_term.on_resize((new_width / font_size) / map_zoom, (new_height / font_size) / map_zoom);
                        ui_term.on_resize((new_width / font_size) * 2, (new_height / font_size));
                    }
                }
            default:
                break;
            }

            map_term.clear(colors::BLANK);
            ui_term.clear(colors::BLANK);
            
            gui::gui_data.start_frame();

            switch (game_state)
            {
            case PLAYING:
                double elapsed = g_zone.update();
                if (elapsed > 0.0)
                {
                    elapsed_time += elapsed;
                    
                    Player* player = (Player*) g_zone.player;
                    if (player.health <= 0)
                    {
                        if (devmode_immortal)
                        {
                            player.health = player.level[Skill.HITPOINTS];
                        }
                        else
                        {
                            game_state = GAME_OVER;
                        }
                    }
                }
                ZoneRenderSettings settings = { { 15 / map_zoom, 0 } };
                g_zone.render(&map_term, &ui_term, settings);

                draw_ui();
                map_term.render(map_zoom, {0, 16});
            case MAIN_MENU:
                draw_mainmenu();
            case GAME_OVER:
                draw_gameover();
            case VICTORY:
                draw_victory();
            }
            
            gui::gui_data.render();
            ui_term.render(1);
            
            rl::endDrawing();

            if (want_exit_floor || (devmode && !gui::want_key_input() && is_key_pressed(NEXT_FLOOR, false)))
            {
                if (current_floor.depth == 10)
                {
                    // Victory screen
                    break;
                }
                load_floor(current_floor.depth + 1);
                want_exit_floor = false;
            }
        };
    }
    
    rl::traceLog(rl::TraceLogLevel.INFO, "C3RL: Shutting down...");
    return 0;
}

fn void draw_mainmenu()
{
    int term_width = ui_term.width;
    int term_height = ui_term.height;

}

fn void draw_gameover()
{
    int term_width = ui_term.width;
    int term_height = ui_term.height;

    IVec2 pos = {term_width / 2, term_height / 3};
    ui_term.write_centered(...pos, "You have been defeated.", colors::WHITE);
}

fn void draw_victory()
{
    int term_width = ui_term.width;
    int term_height = ui_term.height;

    IVec2 pos = {term_width / 2, term_height / 3};
    ui_term.write_centered(...pos, "You were victorious!", colors::WHITE);
}