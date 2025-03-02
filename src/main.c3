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

Zone* g_zone;
bool want_exit_floor;

bool show_visibility;

DungeonFloor* current_floor;

bool devmode;

fn void log(String message, rl::Color color = colors::WHITE)
{
    log_messages.push({message, color});
}

struct GeneratorData
{
    ulong seed;
    int depth;
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

    for (int y = 0; y < 8; ++y)
    {
        for (int x = 0; x < 8; ++x)
        {
            Room* room = mem::new(Room);
            room.new_init({x * 17, y * 17}, {16, 16});
            current_floor.rooms.set({x, y}, room);
        }
    }

    HashMap(<IVec2, bool>) placed;
    HashMap(<IVec2, bool>) adjacent;
    placed.temp_init();
    adjacent.temp_init();

    IVec2 start = {random::next_in_range(&rng, 1, 6), random::next_in_range(&rng, 1, 6)};
    placed.set(start, true);
    adjacent.set({ start.x + 1, start.y }, true);
    adjacent.set({ start.x - 1, start.y }, true);
    adjacent.set({ start.x, start.y + 1 }, true);
    adjacent.set({ start.x, start.y - 1 }, true);

    while (!adjacent.is_empty())
    {
        IVec2[] keys = adjacent.tcopy_keys();
        assert(keys.len > 0, "No adjacent rooms");
        IVec2 next = keys[random::next_in_range(&rng, 0, (int) keys.len - 1)];
        List(<Direction>) neighbors;
        if (next.x > 0 && placed.get({next.x - 1, next.y}) ?? false) neighbors.push(WEST);
        if (next.x < 7 && placed.get({next.x + 1, next.y}) ?? false) neighbors.push(EAST);
        if (next.y > 0 && placed.get({next.x, next.y - 1}) ?? false) neighbors.push(NORTH);
        if (next.y < 7 && placed.get({next.x, next.y + 1}) ?? false) neighbors.push(SOUTH);
        assert(neighbors.len() > 0, "No neighbors for room");

        Direction neighbor = neighbors[random::next_in_range(&rng, 0, (int) neighbors.len() - 1)];
        
        Room* next_room = current_floor.rooms.get(next)!!;
        Room* neighbor_room = current_floor.rooms.get(next + neighbor.dir)!!;

        Door* door = &next_room.doors[neighbor.ordinal - 1];
        door.direction = neighbor;
        door.type = UNLOCKED;

        Door* ndoor = &neighbor_room.doors[FLIP[neighbor.ordinal].ordinal - 1];
        ndoor.direction = FLIP[neighbor.ordinal];
        ndoor.type = UNLOCKED;

        placed.set(next, true);
        adjacent.remove(next);

        if (next.x > 0 && !(placed.get({next.x - 1, next.y}) ?? false)) adjacent.set({next.x - 1, next.y}, true);
        if (next.x < 7 && !(placed.get({next.x + 1, next.y}) ?? false)) adjacent.set({next.x + 1, next.y}, true);
        if (next.y > 0 && !(placed.get({next.x, next.y - 1}) ?? false)) adjacent.set({next.x, next.y - 1}, true);
        if (next.y < 7 && !(placed.get({next.x, next.y + 1}) ?? false)) adjacent.set({next.x, next.y + 1}, true);
    }

    Room* start_room = current_floor.rooms.get(start)!!;
    start_room.type = STARTING;
    start_room.distance_from_start = 0;

    List(<IVec3>) frontier;
    HashMap(<IVec2, int>) seen;
    frontier.temp_init();
    seen.temp_init();
    frontier.push({...start, 0});
    seen.set(start, 0);

    while (!frontier.is_empty())
    {
        IVec3 next = frontier.pop()!!;
        IVec2 pos = {next.x, next.y};
        Room* room = current_floor.rooms.get(pos)!!;
        room.distance_from_start = next.z;
        if (room.doors[Direction.WEST.ordinal - 1].type != WALL && next.x > 0 && (seen.get({next.x - 1, next.y}) ?? 99) > next.z + 1)
        {
            frontier.push({next.x - 1, next.y, next.z + 1});
            seen.set({next.x - 1, next.y}, next.z + 1);
        }
        if (room.doors[Direction.EAST.ordinal - 1].type != WALL && next.x < 7 && (seen.get({next.x + 1, next.y}) ?? 99) > next.z + 1)
        {
            frontier.push({next.x + 1, next.y, next.z + 1});
            seen.set({next.x + 1, next.y}, next.z + 1);
        }
        if (room.doors[Direction.NORTH.ordinal - 1].type != WALL && next.y > 0 && (seen.get({next.x, next.y - 1}) ?? 99) > next.z + 1)
        {
            frontier.push({next.x, next.y - 1, next.z + 1});
            seen.set({next.x, next.y - 1}, next.z + 1);
        }
        if (room.doors[Direction.SOUTH.ordinal - 1].type != WALL && next.y < 7 && (seen.get({next.x, next.y + 1}) ?? 99) > next.z + 1)
        {
            frontier.push({next.x, next.y + 1, next.z + 1});
            seen.set({next.x, next.y + 1}, next.z + 1);
        }
    }

    List(<IVec2>) farthest;
    farthest.temp_init();
    int max_distance = 0;
    seen.@each(; IVec2 p, int d)
    {
        if (d > max_distance)
        {
            max_distance = d;
            farthest.clear();
            farthest.push(p);
        }
        else if (d == max_distance)
        {
            farthest.push(p);
        }
    };

    assert(farthest.len() > 0, "No farthest room found");
    IVec2 boss_pos = farthest[random::next_in_range(&rng, 0, (int) farthest.len() - 1)];
    Room* boss_room = current_floor.rooms.get(boss_pos)!!;
    boss_room.type = BOSS;

    OSN_Context* ctx;
    open_simplex_noise((long) rng.next_long(), &ctx);

    float noise_scale = 12;
    
    for (int y = 0; y < 8; ++y)
    {
        for (int x = 0; x < 8; ++x)
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
                        zone.set_terrain(pos.x+ rx, pos.y + ry, WALL_NW, colors::BLACK, false);
                    }
                    else if (rx == 0 && ry == size.y - 1)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, WALL_SW, colors::BLACK, false);
                    }
                    else if (rx == size.x - 1 && ry == 0)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, WALL_NE, colors::BLACK, false);
                    }
                    else if (rx == size.x - 1 && ry == size.y - 1)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, WALL_SE, colors::BLACK, false);
                    }
                    else if (rx == 0)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, WALL_WEST, colors::BLACK, false);
                    }
                    else if (rx == size.x - 1)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, WALL_EAST, colors::BLACK, false);
                    }
                    else if (ry == 0)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, WALL_NORTH, colors::BLACK, false);
                    }
                    else if (ry == size.y - 1)
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, WALL_SOUTH, colors::BLACK, false);
                    }
                    else
                    {
                        double v0 = open_simplex_noise2(ctx, (double) (pos.x + rx) / noise_scale, (double) (pos.y + ry) / noise_scale);
                        double v1 = open_simplex_noise2(ctx, (double) (pos.x + rx) / noise_scale * 2, (double) (pos.y + ry) / noise_scale * 2);
                        double v2 = open_simplex_noise2(ctx, (double) (pos.x + rx) / noise_scale * 4, (double) (pos.y + ry) / noise_scale * 4);

                        double fval = v0 * (4.0 / 7.0) + v1 * (2.0 / 7.0) + v2 * (1.0 / 7.0);

                        Appearance floor;
                        if (fval < -0.3)
                        {
                            floor = FLOOR_SLABS;
                        }
                        else if (fval < 0.0)
                        {
                            floor = FLOOR_STONE;
                        }
                        else if (fval < 0.2)
                        {
                            floor = FLOOR_DIRT;
                        }
                        else
                        {
                            floor = FLOOR_GRASS;
                        }
                        zone.set_terrain(pos.x + rx, pos.y + ry, floor, colors::BLACK, true);
                    }
                }
            }
            room.generate(current_floor, zone, &rng);
        }
    }

    Player* pl = mem::new(Player);
    pl.new_init(zone, "Player", {start.x * 17 + 7, start.y * 17 + 7});
    zone.add_player(pl);
    pl.explore(start_room.position, {16, 16});
}

fn void onUpdate(double elapsed)
{

}

fn void onRender()
{
    Player* pl = (Player*) g_zone.player;
    int sidebar_width = 60;
    int term_width = ui_term.width;
    int term_height = ui_term.height;
    int map_width = ui_term.width - sidebar_width;

    gui::push_topbar("The Depths of Daemonheim - 7DRL 2025");
    gui::push_bottombar(string::tformat("%-16s", g_zone.name));
    //gui::push_bottombar(string::tformat("Player @ %d %d", ...pl.get_position()));
    //gui::push_bottombar(string::tformat("Mouse @ %d %d", ...pl.zone.get_mouse_position()));
    //gui::push_bottombar(string::tformat("FPS: %d", rl::getFPS()));

    int log_height = 7;
    gui::begin_window("Log", {map_width, 0}, {sidebar_width, log_height});
    
    long start = math::max(log_messages.len() - log_height + 2, 0l);
    for (long i = start; i < log_messages.len(); ++i)
    {
        LogMessage msg = log_messages[i];
        gui::text(msg.message, msg.color);
    }

    gui::end_window();
}

fn void load_zone(ZoneDescription desc)
{
    if (g_zone)
    {
        g_zone.free();
        mem::free(g_zone);
    }
    g_zone = mem::new(Zone);
    g_zone.new_init(desc);
}

fn void load_floor(int depth)
{
    ZoneDescription initial_zone;
    initial_zone.new_init("dungeon", 17 * 8, 17 * 8);
    GeneratorData generator = { 165361613 * ((ulong) depth + 1), depth };
    initial_zone.generator = (ZoneGenerator) &GeneratorData.generate;
    initial_zone.generator_data = &generator;

    log("You descend further into the depths of Daemonheim...", colors::RED);

    load_zone(initial_zone);
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

    random::seed_entropy(&g_rng);
    generate_whole_dungeon_stuff(&g_rng);

    int term_width = 80;
    int term_height = 45;

    rl::initWindow(term_width * font_size, term_height * font_size, "The Depths of Daemonheim - 7DRL 2025");
    rl::setTargetFPS(60);
    rl::setExitKey(0);
    rl::setWindowState(rl::FLAG_WINDOW_RESIZABLE);

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
    initial_zone.new_init("dungeon", 17 * 8, 17 * 8);
    GeneratorData generator = { (ulong) g_rng.next_long(), 0 };
    initial_zone.generator = (ZoneGenerator) &GeneratorData.generate;
    initial_zone.generator_data = &generator;

    load_zone(initial_zone);
    
    gui::gui_data.new_init();

    rl::traceLog(rl::TraceLogLevel.INFO, "C3RL: Starting game loop...");
    
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

            map_term.clear(colors::BLANK);
            ui_term.clear(colors::BLANK);
            
            gui::gui_data.start_frame();

            double elapsed = g_zone.update();
            if (elapsed > 0.0)
            {
                onUpdate(elapsed);
            }
            ZoneRenderSettings settings = { { 15 / map_zoom, 0} };
            g_zone.render(&map_term, settings);

            onRender();
            gui::gui_data.render();

            map_term.render(map_zoom);
            ui_term.render(1);
            
            rl::endDrawing();

            if (want_exit_floor || (devmode && is_key_pressed(NEXT_FLOOR, false)))
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
