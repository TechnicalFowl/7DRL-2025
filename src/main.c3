module dg;

import std::collections::list;
import std::io;
import std::math::random;

import raylib5::rl;

random::Pcg32Random rng;

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

int map_zoom = 2;
VirtualTerminal map_term;
VirtualTerminal ui_term;

Zone* zone;

bool show_visibility;

fn void log(String message, rl::Color color = colors::WHITE)
{
    log_messages.push({message, color});
}

fn void zone_generator(void*, Zone* zone)
{
    for (int y = 0; y < zone.height; ++y)
    {
        for (int x = 0; x < zone.width; ++x)
        {
            if (x == 10 && y == 10) continue;
            if (x == 0 || x == zone.width - 1 || y == 0 || y == zone.height - 1 || random::next_in_range(&rng, 0, 5) == 0)
            {
                zone.set_terrain(x, y, '#', colors::random_color(&rng), colors::BLACK, false);
            }
            else
            {
                zone.set_terrain(x, y, '.', colors::WHITE, colors::BLACK, true);
            }
        }
    }

    Player* pl = mem::new(Player);
    pl.new_init(zone, "Player", {40, 10});
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

    random::seed_entropy(&rng);

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

    ZoneDescription initial_zone;
    initial_zone.new_init("main", 80, 45);
    initial_zone.generator = (ZoneGenerator) &zone_generator;

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
