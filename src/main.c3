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

struct LogMessage
{
    String message;
    rl::Color color;
}
List(<LogMessage>) log_messages;

int map_zoom = 1;
VirtualTerminal map_term;
VirtualTerminal ui_term;

Zone* zone;

bool show_visibility;

DungeonFloor* current_floor;

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
    placed.new_init();
    adjacent.new_init();

    IVec2 start = {random::next_in_range(&rng, 1, 7), random::next_in_range(&rng, 1, 7)};
    placed.set(start, true);
    adjacent.set({ start.x + 1, start.y }, true);
    adjacent.set({ start.x - 1, start.y }, true);
    adjacent.set({ start.x, start.y + 1 }, true);
    adjacent.set({ start.x, start.y - 1 }, true);

    while (!adjacent.is_empty())
    {
        IVec2[] keys = adjacent.tcopy_keys();
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
        ndoor.direction = FLIP[neighbor];
        ndoor.type = UNLOCKED;

        placed.set(next, true);
        adjacent.remove(next);

        if (next.x > 0 && !(placed.get({next.x - 1, next.y}) ?? false)) adjacent.set({next.x - 1, next.y}, true);
        if (next.x < 7 && !(placed.get({next.x + 1, next.y}) ?? false)) adjacent.set({next.x + 1, next.y}, true);
        if (next.y > 0 && !(placed.get({next.x, next.y - 1}) ?? false)) adjacent.set({next.x, next.y - 1}, true);
        if (next.y < 7 && !(placed.get({next.x, next.y + 1}) ?? false)) adjacent.set({next.x, next.y + 1}, true);
    }
    
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
                    if (rx == 0 || rx == size.x - 1 || ry == 0 || ry == size.y - 1)
                    {
                        zone.set_terrain(pos.x+ rx, pos.y + ry, '#', {220, 220, 220, 255}, colors::BLACK, false);
                    }
                    else
                    {
                        zone.set_terrain(pos.x + rx, pos.y + ry, '.', colors::DARK_GREY, colors::BLACK, true);
                    }
                }
            }
            room.generate(zone, &rng);
        }
    }

    Player* pl = mem::new(Player);
    pl.new_init(zone, "Player", {70, 70});
    zone.add_player(pl);
}

fn void onUpdate(double elapsed)
{

}

fn void onRender()
{
    Player* pl = (Player*) zone.player;
    if (rl::isMouseButtonPressed(rl::MouseButton.LEFT))
    {
        if (pl.nav.is_idle())
        {
            IVec2 pos = math::clamp(zone.get_mouse_position(), IVec2 {0, 0}, IVec2 {zone.width - 1, zone.height - 1});
            pl.nav.path_to(zone, pl.get_position(), pos);
        }
        else
        {
            pl.nav.abort();
        }
    }
    if (rl::isKeyPressed(rl::KEY_SPACE))
    {
        pl.vis.clear();
        pl.vis.sweep(pl.get_position(), 10);
    }
    if (rl::isKeyPressed(rl::KEY_F1))
    {
        show_visibility = !show_visibility;
    }

    // Visibility debugging
    if (show_visibility)
    {
        IVec2 player_pos = pl.get_position();
        IVec2 zone_min = player_pos - { map_term.width / 2, map_term.height / 2};

        for (int y = 0; y < map_term.height; ++y)
        {
            for (int x = 0; x < map_term.width; ++x)
            {
                IVec2 term_pos = {x, y} + zone_min;
                if (term_pos[0] < 0 || term_pos[0] >= zone.width || term_pos[1] < 0 || term_pos[1] >= zone.height) continue;
                if (pl.vis.is_visible(term_pos))
                {
                    map_term.set_background(x, y, colors::DARK_GREEN, 5);
                } else if (pl.vis.is_explored(term_pos))
                {
                    map_term.set_background(x, y, colors::DARK_RED, 5);
                }
            }
        }
    }

    int sidebar_width = 60;
    int term_width = ui_term.width;
    int term_height = ui_term.height;
    int map_width = ui_term.width - sidebar_width;

    gui::push_topbar("The Depths of Daemonheim - 7DRL 2025");
    gui::push_bottombar(string::tformat("Player @ %d %d", ...pl.get_position()));
    gui::push_bottombar(string::tformat("Mouse @ %d %d", ...pl.zone.get_mouse_position()));
    gui::push_bottombar(string::tformat("FPS: %d", rl::getFPS()));

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

fn int main(String[] args)
{
    //waitForDebugger();

    rl::traceLog(rl::TraceLogLevel.INFO, "C3RL: Initializing...");

    random::seed_entropy(&g_rng);

    int term_width = 80;
    int term_height = 45;

    rl::initWindow(term_width * font_size, term_height * font_size, "The Depths of Daemonheim - 7DRL 2025");
    rl::setTargetFPS(60);
    rl::setExitKey(0);
    rl::setWindowState(rl::FLAG_WINDOW_RESIZABLE);

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

    map_term.new_init(term_width / map_zoom, term_height / map_zoom, textmode_font);
    ui_term.new_init(term_width * 2, term_height, text_font);

    g_items.new_init();
    g_mobs.new_init();

    ZoneDescription initial_zone;
    initial_zone.new_init("dungeon", 17 * 8, 17 * 8);
    GeneratorData generator = { 16135, 0 };
    initial_zone.generator = (ZoneGenerator) &GeneratorData.generate;
    initial_zone.generator_data = &generator;

    zone = mem::new(Zone);
    zone.new_init(initial_zone);
    
    gui::gui_data.new_init();

    rl::traceLog(rl::TraceLogLevel.INFO, "C3RL: Starting game loop...");
    
    log("You descend into the dungeon...", colors::GREEN);

    while (!rl::windowShouldClose())
    {
        @pool()
        {
            if (rl::isWindowResized())
            {
                int new_width = rl::getScreenWidth();
                int new_height = rl::getScreenHeight();
                map_term.on_resize(new_width, new_height);
                ui_term.on_resize(new_width, new_height);
            }
            
            rl::beginDrawing();
            rl::clearBackground(colors::BLACK);

            map_term.clear(colors::BLANK);
            ui_term.clear(colors::BLANK);
            
            gui::gui_data.start_frame();

            double elapsed = zone.update();
            if (elapsed > 0.0)
            {
                onUpdate(elapsed);
            }
            ZoneRenderSettings settings = { { 7, 0} };
            zone.render(&map_term, settings);

            onRender();
            gui::gui_data.render();

            map_term.render(map_zoom);
            ui_term.render(1);
            
            rl::endDrawing();
        };
    }
    
    rl::traceLog(rl::TraceLogLevel.INFO, "C3RL: Shutting down...");
    return 0;
}
