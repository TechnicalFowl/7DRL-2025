module dg;

import std::collections::list;
import std::collections::map;
import std::io;
import raylib5::rl;

enum Input : int
{
    MOVE_UP,
    MOVE_DOWN,
    MOVE_LEFT,
    MOVE_RIGHT,
    DIAGONAL_UP,
    DIAGONAL_DOWN,

    TOGGLE_ZOOM,
}

struct KeyBind
{
    Input input;
    List(<KeyboardKey>) keys;

    bool down;
    bool was_down;
    bool repeat;

    double last_press_time;
    double last_repeat_time;
}

fn void createBind(Input i, KeyboardKey... keys)
{
    KeyBind* bind = mem::new(KeyBind);
    bind.input = i;
    bind.keys.new_init_with_array(keys);

    g_keymap.binds.set(i.ordinal, bind);
}

struct KeyMapping
{
    HashMap(<int, KeyBind*>) binds;
    double repeat_delay;
    double repeat_rate;
}
KeyMapping g_keymap;

fn void init_inputs()
{
    g_keymap.binds.new_init();
    g_keymap.repeat_delay = 0.5;
    g_keymap.repeat_rate = 0.1;

    createBind(MOVE_UP, rl::KEY_UP);
    createBind(MOVE_DOWN, rl::KEY_DOWN);
    createBind(MOVE_LEFT, rl::KEY_LEFT);
    createBind(MOVE_RIGHT, rl::KEY_RIGHT);
    createBind(DIAGONAL_UP, rl::KEY_LEFT_SHIFT, rl::KEY_RIGHT_SHIFT);
    createBind(DIAGONAL_DOWN, rl::KEY_LEFT_CONTROL, rl::KEY_RIGHT_CONTROL);

    createBind(TOGGLE_ZOOM, rl::KEY_LEFT_ALT, rl::KEY_RIGHT_ALT);
}

fn void update_inputs()
{
    g_keymap.binds.@each(; int, KeyBind* bind)
    {
        bind.was_down = bind.down;
        bind.down = false;
        foreach (k: bind.keys)
        {
            if (rl::isKeyDown(k))
            {
                bind.down = true;
                break;
            }
        }
        bind.repeat = false;
        if (bind.down && !bind.was_down)
        {
            bind.last_press_time = rl::getTime();
            bind.last_repeat_time = bind.last_press_time;
        }
        else if (bind.down)
        {
            double time_down = rl::getTime() - bind.last_press_time;
            if (bind.last_press_time == bind.last_repeat_time)
            {
                if (time_down > g_keymap.repeat_delay)
                {
                    bind.repeat = true;
                    bind.last_repeat_time = rl::getTime();
                }
            }
            else
            {
                double time_repeat = rl::getTime() - bind.last_repeat_time;
                if (time_repeat > g_keymap.repeat_rate)
                {
                    bind.repeat = true;
                    bind.last_repeat_time = rl::getTime();
                }
            }
        }
    };
}

fn bool is_key_down(Input i)
{
    KeyBind*! bind = g_keymap.binds.get(i.ordinal);
    if (catch bind)
    {
        return false;
    }
    return bind.down;
}

fn bool is_key_pressed(Input i, bool allow_repeat=true)
{
    KeyBind*! bind = g_keymap.binds.get(i.ordinal);
    if (catch bind)
    {
        return false;
    }
    return bind.down && (!bind.was_down || (allow_repeat && bind.repeat));
}