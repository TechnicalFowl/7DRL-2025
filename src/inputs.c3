module dg;

import std::collections::list;
import std::collections::map;
import std::io;
import raylib5::rl;

enum Input : inline int
{
    MOVE_UP,
    MOVE_DOWN,
    MOVE_LEFT,
    MOVE_RIGHT,
    MOVE_UP_LEFT,
    MOVE_UP_RIGHT,
    MOVE_DOWN_LEFT,
    MOVE_DOWN_RIGHT,
    DIAGONAL_UP,
    DIAGONAL_DOWN,

    WAIT,
    CANCEL,

    QUAFF,
    GRAB,
    DROP,
    USE,
    EXAMINE,
    EQUIP,
    ZAP,

    EQUIPMENT_TAB,
    INVENTORY_TAB,
    SPELLBOOK_TAB,
    SKILLS_TAB,

    TOGGLE_ZOOM,
    TOGGLE_TEXTMODE,

    // dev-mode
    PATH_TO_BOSS,
    REVEAL_MAP,
    NEXT_FLOOR,
    SPAWN_ITEM,
}

struct KeyBind
{
    Input input;
    KeyboardKey[2] keys;

    bool down;
    bool was_down;
    bool repeat;

    double last_press_time;
    double last_repeat_time;
}

fn void createBind(Input i, KeyboardKey key1, KeyboardKey key2 = (KeyboardKey) 0)
{
    KeyBind* bind = mem::new(KeyBind);
    bind.input = i;
    bind.keys[0] = key1;
    bind.keys[1] = key2;
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

    createBind(MOVE_UP, rl::KEY_UP, rl::KEY_KP_8);
    createBind(MOVE_DOWN, rl::KEY_DOWN, rl::KEY_KP_2);
    createBind(MOVE_LEFT, rl::KEY_LEFT, rl::KEY_KP_4);
    createBind(MOVE_RIGHT, rl::KEY_RIGHT, rl::KEY_KP_6);
    createBind(MOVE_UP_LEFT, rl::KEY_KP_7);
    createBind(MOVE_UP_RIGHT, rl::KEY_KP_9);
    createBind(MOVE_DOWN_LEFT, rl::KEY_KP_1);
    createBind(MOVE_DOWN_RIGHT, rl::KEY_KP_3);
    createBind(DIAGONAL_UP, rl::KEY_LEFT_SHIFT, rl::KEY_RIGHT_SHIFT);
    createBind(DIAGONAL_DOWN, rl::KEY_LEFT_CONTROL, rl::KEY_RIGHT_CONTROL);

    createBind(WAIT, rl::KEY_SPACE, rl::KEY_KP_5);
    createBind(CANCEL, rl::KEY_ESCAPE);

    createBind(QUAFF, rl::KEY_Q);
    createBind(GRAB, rl::KEY_G);
    createBind(DROP, rl::KEY_D);
    createBind(USE, rl::KEY_F);
    createBind(EXAMINE, rl::KEY_X);
    createBind(EQUIP, rl::KEY_E);
    createBind(ZAP, rl::KEY_Z);

    createBind(EQUIPMENT_TAB, rl::KEY_U);
    createBind(INVENTORY_TAB, rl::KEY_I);
    createBind(SPELLBOOK_TAB, rl::KEY_O);
    createBind(SKILLS_TAB, rl::KEY_P);
    
    createBind(TOGGLE_ZOOM, rl::KEY_LEFT_ALT, rl::KEY_RIGHT_ALT);
    createBind(TOGGLE_TEXTMODE, rl::KEY_F1);

    createBind(PATH_TO_BOSS, rl::KEY_F11);
    createBind(REVEAL_MAP, rl::KEY_F12);
    createBind(NEXT_FLOOR, rl::KEY_F10);
    createBind(SPAWN_ITEM, rl::KEY_INSERT);
}

fn KeyboardKey[2] get_bind(Input in)
{
    KeyBind*! bind = g_keymap.binds.get(in.ordinal);
    if (catch bind)
    {
        return {(KeyboardKey) 0, (KeyboardKey) 0};
    }
    return bind.keys;
}

fn void update_inputs()
{
    g_keymap.binds.@each(; int, KeyBind* bind)
    {
        bind.was_down = bind.down;
        bind.down = false;
        foreach (k: bind.keys)
        {
            if (rl::isKeyDown((KeyboardKey) k))
            {
                bind.down = true;
                break;
            }
        }
        bind.repeat = false;
        if (bind.down && !bind.was_down)
        {
            //io::printfn("Input %s pressed", bind.input);
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

fn bool is_key_pressed(Input i, bool allow_repeat=true, bool consume_press=false)
{
    KeyBind*! bind = g_keymap.binds.get(i.ordinal);
    if (catch bind)
    {
        return false;
    }
    bool pressed = bind.down && (!bind.was_down || (allow_repeat && bind.repeat));
    if (pressed && consume_press)
    {
        bind.was_down = bind.down;
        bind.repeat = false;
    }
    return pressed;
}

fn String getKeyName(KeyboardKey k)
{
    switch (k)
    {
    case rl::KEY_A: return "A";
    case rl::KEY_B: return "B";
    case rl::KEY_C: return "C";
    case rl::KEY_D: return "D";
    case rl::KEY_E: return "E";
    case rl::KEY_F: return "F";
    case rl::KEY_G: return "G";
    case rl::KEY_H: return "H";
    case rl::KEY_I: return "I";
    case rl::KEY_J: return "J";
    case rl::KEY_K: return "K";
    case rl::KEY_L: return "L";
    case rl::KEY_M: return "M";
    case rl::KEY_N: return "N";
    case rl::KEY_O: return "O";
    case rl::KEY_P: return "P";
    case rl::KEY_Q: return "Q";
    case rl::KEY_R: return "R";
    case rl::KEY_S: return "S";
    case rl::KEY_T: return "T";
    case rl::KEY_U: return "U";
    case rl::KEY_V: return "V";
    case rl::KEY_W: return "W";
    case rl::KEY_X: return "X";
    case rl::KEY_Y: return "Y";
    case rl::KEY_Z: return "Z";
    case rl::KEY_ZERO: return "0";
    case rl::KEY_ONE: return "1";
    case rl::KEY_TWO: return "2";
    case rl::KEY_THREE: return "3";
    case rl::KEY_FOUR: return "4";
    case rl::KEY_FIVE: return "5";
    case rl::KEY_SIX: return "6";
    case rl::KEY_SEVEN: return "7";
    case rl::KEY_EIGHT: return "8";
    case rl::KEY_NINE: return "9";
    case rl::KEY_SPACE: return "SPACE";
    case rl::KEY_ESCAPE: return "ESC";
    case rl::KEY_ENTER: return "ENTER";
    case rl::KEY_TAB: return "TAB";
    case rl::KEY_BACKSPACE: return "BACKSPACE";
    case rl::KEY_INSERT: return "INS";
    case rl::KEY_DELETE: return "DEL";
    case rl::KEY_RIGHT: return "RIGHT";
    case rl::KEY_LEFT: return "LEFT";
    case rl::KEY_DOWN: return "DOWN";
    case rl::KEY_UP: return "UP";
    case rl::KEY_PAGE_UP: return "PGUP";
    case rl::KEY_PAGE_DOWN: return "PGDN";
    case rl::KEY_HOME: return "HOME";
    case rl::KEY_END: return "END";
    case rl::KEY_CAPS_LOCK: return "CAPS";
    case rl::KEY_SCROLL_LOCK: return "SCROLL";
    case rl::KEY_NUM_LOCK: return "NUM";
    case rl::KEY_PRINT_SCREEN: return "PRTSCR";
    case rl::KEY_PAUSE: return "PAUSE";
    case rl::KEY_F1: return "F1";
    case rl::KEY_F2: return "F2";
    case rl::KEY_F3: return "F3";
    case rl::KEY_F4: return "F4";
    case rl::KEY_F5: return "F5";
    case rl::KEY_F6: return "F6";
    case rl::KEY_F7: return "F7";
    case rl::KEY_F8: return "F8";
    case rl::KEY_F9: return "F9";
    case rl::KEY_F10: return "F10";
    case rl::KEY_F11: return "F11";
    case rl::KEY_F12: return "F12";
    case rl::KEY_LEFT_SHIFT: return "LSHIFT";
    case rl::KEY_LEFT_CONTROL: return "LCTRL";
    case rl::KEY_LEFT_ALT: return "LALT";
    case rl::KEY_RIGHT_SHIFT: return "RSHIFT";
    case rl::KEY_RIGHT_CONTROL: return "RCTRL";
    case rl::KEY_RIGHT_ALT: return "RALT";
    case rl::KEY_GRAVE: return "`";
    case rl::KEY_SLASH: return "/";
    case rl::KEY_BACKSLASH: return "\\";
    case rl::KEY_COMMA: return ",";
    case rl::KEY_PERIOD: return ".";
    case rl::KEY_SEMICOLON: return ";";
    case rl::KEY_APOSTROPHE: return "'";
    case rl::KEY_LEFT_BRACKET: return "[";
    case rl::KEY_RIGHT_BRACKET: return "]";
    case rl::KEY_MINUS: return "-";
    case rl::KEY_EQUAL: return "=";
    case rl::KEY_KP_0: return "KP0";
    case rl::KEY_KP_1: return "KP1";
    case rl::KEY_KP_2: return "KP2";
    case rl::KEY_KP_3: return "KP3";
    case rl::KEY_KP_4: return "KP4";
    case rl::KEY_KP_5: return "KP5";
    case rl::KEY_KP_6: return "KP6";
    case rl::KEY_KP_7: return "KP7";
    case rl::KEY_KP_8: return "KP8";
    case rl::KEY_KP_9: return "KP9";
    case rl::KEY_KP_DECIMAL: return "KP.";
    case rl::KEY_KP_DIVIDE: return "KP/";
    case rl::KEY_KP_MULTIPLY: return "KP*";
    case rl::KEY_KP_SUBTRACT: return "KP-";
    case rl::KEY_KP_ADD: return "KP+";
    case rl::KEY_KP_ENTER: return "KPENTER";
    case rl::KEY_KP_EQUAL: return "KPEQUAL";
    case rl::KEY_BACK: return "BACK";
    default: return "UNKNOWN";
    }
}

fn char getKeyIcon(KeyboardKey k)
{
    switch (k)
    {
    case rl::KEY_A: return 'A';
    case rl::KEY_B: return 'B';
    case rl::KEY_C: return 'C';
    case rl::KEY_D: return 'D';
    case rl::KEY_E: return 'E';
    case rl::KEY_F: return 'F';
    case rl::KEY_G: return 'G';
    case rl::KEY_H: return 'H';
    case rl::KEY_I: return 'I';
    case rl::KEY_J: return 'J';
    case rl::KEY_K: return 'K';
    case rl::KEY_L: return 'L';
    case rl::KEY_M: return 'M';
    case rl::KEY_N: return 'N';
    case rl::KEY_O: return 'O';
    case rl::KEY_P: return 'P';
    case rl::KEY_Q: return 'Q';
    case rl::KEY_R: return 'R';
    case rl::KEY_S: return 'S';
    case rl::KEY_T: return 'T';
    case rl::KEY_U: return 'U';
    case rl::KEY_V: return 'V';
    case rl::KEY_W: return 'W';
    case rl::KEY_X: return 'X';
    case rl::KEY_Y: return 'Y';
    case rl::KEY_Z: return 'Z';
    case rl::KEY_ZERO: return '0';
    case rl::KEY_ONE: return '1';
    case rl::KEY_TWO: return '2';
    case rl::KEY_THREE: return '3';
    case rl::KEY_FOUR: return '4';
    case rl::KEY_FIVE: return '5';
    case rl::KEY_SIX: return '6';
    case rl::KEY_SEVEN: return '7';
    case rl::KEY_EIGHT: return '8';
    case rl::KEY_NINE: return '9';
    case rl::KEY_SPACE: return ' ';
    case rl::KEY_ESCAPE: return 255;
    case rl::KEY_ENTER: return 255;
    case rl::KEY_TAB: return 255;
    case rl::KEY_BACKSPACE: return 255;
    case rl::KEY_INSERT: return 255;
    case rl::KEY_DELETE: return 255;
    case rl::KEY_RIGHT: return 26;
    case rl::KEY_LEFT: return 27;
    case rl::KEY_DOWN: return 25;
    case rl::KEY_UP: return 24;
    case rl::KEY_PAGE_UP: return 255;
    case rl::KEY_PAGE_DOWN: return 255;
    case rl::KEY_HOME: return 255;
    case rl::KEY_END: return 255;
    case rl::KEY_CAPS_LOCK: return 255;
    case rl::KEY_SCROLL_LOCK: return 255;
    case rl::KEY_NUM_LOCK: return 255;
    case rl::KEY_PRINT_SCREEN: return 255;
    case rl::KEY_PAUSE: return 255;
    case rl::KEY_F1: return 255;
    case rl::KEY_F2: return 255;
    case rl::KEY_F3: return 255;
    case rl::KEY_F4: return 255;
    case rl::KEY_F5: return 255;
    case rl::KEY_F6: return 255;
    case rl::KEY_F7: return 255;
    case rl::KEY_F8: return 255;
    case rl::KEY_F9: return 255;
    case rl::KEY_F10: return 255;
    case rl::KEY_F11: return 255;
    case rl::KEY_F12: return 255;
    case rl::KEY_LEFT_SHIFT: return 255;
    case rl::KEY_LEFT_CONTROL: return 255;
    case rl::KEY_LEFT_ALT: return 255;
    case rl::KEY_RIGHT_SHIFT: return 255;
    case rl::KEY_RIGHT_CONTROL: return 255;
    case rl::KEY_RIGHT_ALT: return 255;
    case rl::KEY_GRAVE: return '`';
    case rl::KEY_SLASH: return '/';
    case rl::KEY_BACKSLASH: return '\\';
    case rl::KEY_COMMA: return ',';
    case rl::KEY_PERIOD: return '.';
    case rl::KEY_SEMICOLON: return ';';
    case rl::KEY_APOSTROPHE: return '\'';
    case rl::KEY_LEFT_BRACKET: return '[';
    case rl::KEY_RIGHT_BRACKET: return ']';
    case rl::KEY_MINUS: return '-';
    case rl::KEY_EQUAL: return '=';
    case rl::KEY_KP_0: return '0';
    case rl::KEY_KP_1: return '1';
    case rl::KEY_KP_2: return '2';
    case rl::KEY_KP_3: return '3';
    case rl::KEY_KP_4: return '4';
    case rl::KEY_KP_5: return '5';
    case rl::KEY_KP_6: return '6';
    case rl::KEY_KP_7: return '7';
    case rl::KEY_KP_8: return '8';
    case rl::KEY_KP_9: return '9';
    case rl::KEY_KP_DECIMAL: return '.';
    case rl::KEY_KP_DIVIDE: return '/';
    case rl::KEY_KP_MULTIPLY: return '*';
    case rl::KEY_KP_SUBTRACT: return '-';
    case rl::KEY_KP_ADD: return '+';
    case rl::KEY_KP_ENTER: return 255;
    case rl::KEY_KP_EQUAL: return '=';
    case rl::KEY_BACK: return 255;
    default: return '?';
    }
}