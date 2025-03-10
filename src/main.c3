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

Texture2D title_screen;

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
bool view_settings;

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
    int depth;

    Player* old_player;
}

fn void GeneratorData.generate(&self, Zone* zone)
{
    random::Pcg32Random rng;
    random::seed_entropy(&rng);

    zone.name = string::new_format("Floor %d", self.depth + 1);

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
    current_floor.boss_room = boss_room;
    
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
        pl.entity.look = self.old_player.look;
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
    GeneratorData generator = { depth, g_zone && depth != 0 ? (Player*) g_zone.player : null };
    initial_zone.generator = (ZoneGenerator) &GeneratorData.generate;
    initial_zone.generator_data = &generator;

    if (depth == 0)
    {
        want_exit_floor = false;
        log_messages.clear();
        reset_stats();

        log("You descend into the depths of Daemonheim...", colors::RED);
    }
    else
    {
        log("You descend further into the depths of Daemonheim...", colors::RED);
    }

    load_zone(initial_zone);

    inv_action = NO_ACTION;
}

fn int main(String[] args)
{
    //waitForDebugger();

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
    
    load_settings();

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

    title_screen = rl::loadTexture("resources/startimage.png");

    textmode = false;
    map_term.new_init(term_width / map_zoom, term_height / map_zoom, textmode ? textmode_font : sprite_font);
    ui_term.new_init(term_width * 2, term_height, text_font);

    g_items.new_init();
    g_mobs.new_init();
    
    gui::gui_data.new_init();
    init_ui();

    rl::traceLog(rl::TraceLogLevel.INFO, "C3RL: Starting game loop...");
    
    game_state = MAIN_MENU;

    while LOOP: (!rl::windowShouldClose())
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
                if (view_settings)
                {
                    draw_settings();
                    break;
                }
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

                    IVec2 player_pos = player.get_position();
                    IVec2 player_room = {player_pos.x / 17, player_pos.y / 17};
                    Room* room = current_floor.rooms.get(player_room)!!;
                    if (room.type == BOSS)
                    {
                        bool all_dead = true;
                        for (int y = room.position.y; y < room.position.y + room.size.y && all_dead; ++y)
                        {
                            for (int x = room.position.x; x < room.position.x + room.size.x; ++x)
                            {
                                ZoneCell* cell = g_zone.get_cell(x, y)!!;
                                if (cell.entities.first().type == Monster.typeid ?? false)
                                {
                                    all_dead = false;
                                    break;
                                }
                            }
                        }
                        if (all_dead && !room.has_spawned_exit)
                        {
                            room.spawn_exit_hole(g_zone);
                            room.has_spawned_exit = true;
                        }
                    }
                }
                ZoneRenderSettings settings = { { 15 / map_zoom, 0 } };
                g_zone.render(&map_term, &ui_term, settings);

                draw_ui();
                map_term.render(map_zoom, {0, 16});
            case MAIN_MENU:
                if (view_settings)
                {
                    draw_settings();
                }
                else
                {
                    if (!draw_mainmenu())
                    {
                        break LOOP;
                    }
                }
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
                if (current_floor.depth == 9)
                {
                    game_state = VICTORY;
                }
                else
                {
                    load_floor(current_floor.depth + 1);
                }
                want_exit_floor = false;
            }
        };
    }
    
    rl::traceLog(rl::TraceLogLevel.INFO, "C3RL: Shutting down...");
    return 0;
}

fn bool draw_mainmenu()
{
    int term_width = ui_term.width;
    int term_height = ui_term.height;

    int screen_width = rl::getScreenWidth();
    int screen_height = rl::getScreenHeight();
    int ox = (screen_width / 2 - (title_screen.width * 3) / 2);
    int oy = (screen_height / 2 - (title_screen.height * 3) / 2);
    rl::drawTextureEx(title_screen, {ox, oy}, 0.0, 3, colors::WHITE);

    gui::begin_window("Main Menu", {term_width / 2 - 25, term_height / 2 + 5}, {15, 20}, false);
    if (gui::button("Start Game"))
    {
        load_floor(0);
        game_state = PLAYING;
        gui::open_popup("Tutorial");
    }
    if (gui::button("  Settings"))
    {
        view_settings = true;
    }
    if (gui::button("      Exit"))
    {
        return false;
    }
    gui::end_window();
    
    gui::begin_window("Main Menu", {term_width / 2 + 15, term_height / 2 + 5}, {30, 20}, false);
    gui::text("Created for 7DRL 2025");
    gui::text("");
    gui::text("Programming by");
    gui::text("    TechnicalFowl");
    gui::text("Art by:");
    gui::text("    Pepper ");
    gui::end_window();
    return true;
}

fn void draw_settings()
{
    int term_width = ui_term.width;
    int term_height = ui_term.height;

    if (is_key_pressed(CANCEL, false) && gui::active_input == {-1, -1})
    {
        save_settings();
        view_settings = false;
    }

    gui::begin_window("Settings", {term_width / 2 - 55, term_height / 2 - 20}, {50, 40}, false);

    gui::text("");
    gui::text("");
    if (gui::button(g_settings.scroll_to_wait ? "Scroll to wait? ON" : "Scroll to wait? OFF"))
    {
        g_settings.scroll_to_wait = !g_settings.scroll_to_wait;
    }
    gui::icon(WARRIOR_IDLE1); gui::icon(ITEM_SWORD0); gui::icon(ITEM_BOW0); gui::icon(ITEM_STAFF0); gui::text("");
    if (gui::button(textmode ? "Textmode: TEXT" : "Textmode: SPRITE"))
    {
        textmode = !textmode;
    }

    if (game_state == PLAYING)
    {
        gui::vertical_separator(5);
        if (gui::button("Restart Game"))
        {
            load_floor(0);
            view_settings = false;
            save_settings();
        }
    }

    gui::end_window();

    gui::begin_window("Controls", {term_width / 2 + 5, term_height / 2 - 20}, {50, 40}, false);

    gui::text("");
    gui::text("       Controls   Primary Secondary");
    gui::text("");
    gui::text("        Move Up"); gui::same_line(); gui::input_selector(MOVE_UP, 0); gui::same_line(); gui::input_selector(MOVE_UP, 1);
    gui::text("      Move Down"); gui::same_line(); gui::input_selector(MOVE_DOWN, 0); gui::same_line(); gui::input_selector(MOVE_DOWN, 1);
    gui::text("      Move Left"); gui::same_line(); gui::input_selector(MOVE_LEFT, 0); gui::same_line(); gui::input_selector(MOVE_LEFT, 1);
    gui::text("     Move Right"); gui::same_line(); gui::input_selector(MOVE_RIGHT, 0); gui::same_line(); gui::input_selector(MOVE_RIGHT, 1);
    gui::text("   Move Up-Left"); gui::same_line(); gui::input_selector(MOVE_UP_LEFT, 0); gui::same_line(); gui::input_selector(MOVE_UP_LEFT, 1);
    gui::text("  Move Up-Right"); gui::same_line(); gui::input_selector(MOVE_UP_RIGHT, 0); gui::same_line(); gui::input_selector(MOVE_UP_RIGHT, 1);
    gui::text(" Move Down-Left"); gui::same_line(); gui::input_selector(MOVE_DOWN_LEFT, 0); gui::same_line(); gui::input_selector(MOVE_DOWN_LEFT, 1);
    gui::text("Move Down-Right"); gui::same_line(); gui::input_selector(MOVE_DOWN_RIGHT, 0); gui::same_line(); gui::input_selector(MOVE_DOWN_RIGHT, 1);
    gui::text("    Diagonal Up"); gui::same_line(); gui::input_selector(DIAGONAL_UP, 0); gui::same_line(); gui::input_selector(DIAGONAL_UP, 1);
    gui::text("  Diagonal Down"); gui::same_line(); gui::input_selector(DIAGONAL_DOWN, 0); gui::same_line(); gui::input_selector(DIAGONAL_DOWN, 1);
    gui::text("");
    gui::text("         Cancel"); gui::same_line(); gui::input_selector(CANCEL, 0); gui::same_line(); gui::input_selector(CANCEL, 1);
    gui::text("           Wait"); gui::same_line(); gui::input_selector(WAIT, 0); gui::same_line(); gui::input_selector(WAIT, 1);
    gui::text("");
    gui::text("         Attune"); gui::same_line(); gui::input_selector(ATTUNE, 0); gui::same_line(); gui::input_selector(ATTUNE, 1);
    gui::text("           Drop"); gui::same_line(); gui::input_selector(DROP, 0); gui::same_line(); gui::input_selector(DROP, 1);
    gui::text("          Equip"); gui::same_line(); gui::input_selector(EQUIP, 0); gui::same_line(); gui::input_selector(EQUIP, 1);
    gui::text("        Examine"); gui::same_line(); gui::input_selector(EXAMINE, 0); gui::same_line(); gui::input_selector(EXAMINE, 1);
    gui::text("           Grab"); gui::same_line(); gui::input_selector(GRAB, 0); gui::same_line(); gui::input_selector(GRAB, 1);
    gui::text("            Use"); gui::same_line(); gui::input_selector(USE, 0); gui::same_line(); gui::input_selector(USE, 1);
    gui::text("          Quaff"); gui::same_line(); gui::input_selector(QUAFF, 0); gui::same_line(); gui::input_selector(QUAFF, 1);
    gui::text("            Zap"); gui::same_line(); gui::input_selector(ZAP, 0); gui::same_line(); gui::input_selector(ZAP, 1);
    gui::text("");
    gui::text("  Equipment Tab"); gui::same_line(); gui::input_selector(EQUIPMENT_TAB, 0); gui::same_line(); gui::input_selector(EQUIPMENT_TAB, 1);
    gui::text("  Inventory Tab"); gui::same_line(); gui::input_selector(INVENTORY_TAB, 0); gui::same_line(); gui::input_selector(INVENTORY_TAB, 1);
    gui::text("  Spellbook Tab"); gui::same_line(); gui::input_selector(SPELLBOOK_TAB, 0); gui::same_line(); gui::input_selector(SPELLBOOK_TAB, 1);
    gui::text("     Skills Tab"); gui::same_line(); gui::input_selector(SKILLS_TAB, 0); gui::same_line(); gui::input_selector(SKILLS_TAB, 1);
    gui::text("");
    gui::text("    Toggle Zoom"); gui::same_line(); gui::input_selector(TOGGLE_ZOOM, 0); gui::same_line(); gui::input_selector(TOGGLE_ZOOM, 1);
    gui::text("Toggle Textmode"); gui::same_line(); gui::input_selector(TOGGLE_TEXTMODE, 0); gui::same_line(); gui::input_selector(TOGGLE_TEXTMODE, 1);
    gui::end_window();
}

IVec2 stats_draw_base;
fn void write_stat(String key, double value)
{
    ui_term.write_centered(...stats_draw_base, string::tformat("%30s: %-7.0f", key, value), colors::WHITE);
    stats_draw_base.y++;
}

fn void draw_gameover()
{
    int term_width = ui_term.width;
    int term_height = ui_term.height;

    IVec2 pos = {term_width / 2, term_height / 3};
    ui_term.write_centered(...pos, "You have been defeated.", colors::WHITE);

    stats_draw_base = {term_width / 2 - 30, term_height / 3 + 4};
    write_stat("Turns", g_stats.turns);
    write_stat("Distance Travelled", g_stats.distance_traveled);
    write_stat("Monsters Killed", g_stats.enemies_killed);
    write_stat("Damage Dealt", g_stats.damage_dealt);
    write_stat("Damage Taken", g_stats.damage_taken);
    write_stat("Runes Consumed", g_stats.runes_consumed);
    write_stat("Rations Eaten", g_stats.rations_eaten);
    write_stat("Potions Drank", g_stats.potions_drank);
    write_stat("Time Spent Waiting", g_stats.time_spent_waiting);
    write_stat("Time Spent Rooted", g_stats.time_spent_rooted);
    write_stat("Doors Opened", g_stats.doors_opened);

    stats_draw_base = {term_width / 2 + 20, term_height / 3 + 4};
    write_stat("Levels Gained", g_stats.levels_gained);
    write_stat("Experience Gained", g_stats.experience_gained);
    write_stat("Ore Mined", g_stats.ore_mined);
    write_stat("Ore Smelted", g_stats.ore_smelted);
    write_stat("Items Smithed", g_stats.items_smithed);
    write_stat("Logs Chopped", g_stats.logs_chopped);
    write_stat("Crates Looted", g_stats.crates_looted);
    write_stat("Chests Opened", g_stats.chests_opened);
    write_stat("Items Picked Up", g_stats.items_picked_up);
    write_stat("Coins Picked Up", g_stats.gold_picked_up);
    write_stat("Coins Spent", g_stats.gold_spent);

    gui::begin_window("Restart", {term_width / 2 - 5, term_height / 3 + 18}, {20, 2}, false);

    if (gui::button("Play Again?"))
    {
        load_floor(0);
        game_state = PLAYING;
    }

    gui::end_window();
}

fn void draw_victory()
{
    int term_width = ui_term.width;
    int term_height = ui_term.height;

    IVec2 pos = {term_width / 2, term_height / 3};
    ui_term.write_centered(...pos, "You were victorious!", colors::WHITE);

    stats_draw_base = {term_width / 2 - 30, term_height / 3 + 4};
    write_stat("Turns", g_stats.turns);
    write_stat("Distance Travelled", g_stats.distance_traveled);
    write_stat("Monsters Killed", g_stats.enemies_killed);
    write_stat("Damage Dealt", g_stats.damage_dealt);
    write_stat("Damage Taken", g_stats.damage_taken);
    write_stat("Runes Consumed", g_stats.runes_consumed);
    write_stat("Rations Eaten", g_stats.rations_eaten);
    write_stat("Potions Drank", g_stats.potions_drank);
    write_stat("Time Spent Waiting", g_stats.time_spent_waiting);
    write_stat("Time Spent Rooted", g_stats.time_spent_rooted);
    write_stat("Doors Opened", g_stats.doors_opened);

    stats_draw_base = {term_width / 2 + 20, term_height / 3 + 4};
    write_stat("Levels Gained", g_stats.levels_gained);
    write_stat("Experience Gained", g_stats.experience_gained);
    write_stat("Ore Mined", g_stats.ore_mined);
    write_stat("Ore Smelted", g_stats.ore_smelted);
    write_stat("Items Smithed", g_stats.items_smithed);
    write_stat("Logs Chopped", g_stats.logs_chopped);
    write_stat("Crates Looted", g_stats.crates_looted);
    write_stat("Chests Opened", g_stats.chests_opened);
    write_stat("Items Picked Up", g_stats.items_picked_up);
    write_stat("Coins Picked Up", g_stats.gold_picked_up);
    write_stat("Coins Spent", g_stats.gold_spent);

    gui::begin_window("Restart", {term_width / 2 - 5, term_height / 3 + 18}, {20, 2}, false);

    if (gui::button("Play Again?"))
    {
        load_floor(0);
        game_state = PLAYING;
    }

    gui::end_window();
}

fn void save_settings()
{
    @pool()
    {
        File! out = file::open("settings.ini", "wb");
        if (catch out)
        {
            io::printfn("Failed to write settings.ini");
            return;
        }
        io::fprintf(&out, "scroll_to_wait=%s\n", g_settings.scroll_to_wait ? "true" : "false")!!;
        for (int i = 0; i < Input.elements; ++i)
        {
            KeyBind* bind = g_keymap.binds.get(i)!!;
            io::fprintf(&out, "%s0=%d\n", Input.names[i], bind.keys[0])!!;
            if (bind.keys[1] != 0) io::fprintf(&out, "%s1=%d\n", Input.names[i], bind.keys[1])!!;
        }
        out.close()!!;
    };
}

fn void load_settings()
{
    @pool()
    {
        char[]! settings_text = file::load_temp("settings.ini");
        if (catch settings_text)
        {
            save_settings();
            return;
        }
        String settings_str = (String) settings_text[:settings_text.len];
        String[] lines = settings_str.split("\n", 0, allocator::temp());
        foreach (l: lines)
        {
            String[] parts = l.split("=", 0, allocator::temp());
            if (parts.len != 2) continue;
            String key = parts[0].trim();
            String value = parts[1].trim();
            if (key == "scroll_to_wait")
            {
                g_settings.scroll_to_wait = value == "true";
            }
            if (key[key.len - 1] == '0' || key[key.len - 1] == '1')
            {
                int alt = key[key.len - 1] == '0' ? 0 : 1;
                key = key[:key.len - 1];
                for (int i = 0; i < Input.elements; ++i)
                {
                    if (key == Input.names[i])
                    {
                        KeyBind* bind = g_keymap.binds.get(i)!!;
                        bind.keys[alt] = (KeyboardKey) value.to_int() ?? 0;
                    }
                }
            }
        }
    };
}
