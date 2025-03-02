module dg;

import raylib5::rl;

struct Appearance
{
    char glyph;
    rl::Color color;
    int sprite_index;
}

const Appearance EMPTY_LOOK = {' ', colors::MAGENTA, -1 };

const Appearance FLOOR_STONE = { '.', colors::DARKER_GREY, 0 * 16 + 0 };
const Appearance FLOOR_DIRT = { ',', {90, 79, 46, 255}, 1 * 16 + 0 };
const Appearance FLOOR_SLABS = { '.', colors::DARK_GREY, 2 * 16 + 0 };
const Appearance FLOOR_GRASS = { ',', {37, 66, 40, 255}, 3 * 16 + 0 };

const Appearance WALL_NORTH = { '#', {220, 220, 220, 255}, 0 * 16 + 3 };
const Appearance WALL_SOUTH = { '#', {220, 220, 220, 255}, 2 * 16 + 3 };
const Appearance WALL_EAST = { '#', {220, 220, 220, 255}, 1 * 16 + 4 };
const Appearance WALL_WEST = { '#', {220, 220, 220, 255}, 1 * 16 + 2 };
const Appearance WALL_NE = { '#', {220, 220, 220, 255}, 0 * 16 + 4 };
const Appearance WALL_NW = { '#', {220, 220, 220, 255}, 0 * 16 + 2 };
const Appearance WALL_SE = { '#', {220, 220, 220, 255}, 2 * 16 + 4 };
const Appearance WALL_SW = { '#', {220, 220, 220, 255}, 2 * 16 + 2 };
const Appearance PILLAR = { '#', {220, 220, 220, 255}, 1 * 16 + 3 };

const Appearance DOOR_NORTH_L = { '+', colors::BROWN, 0 * 16 + 5 };
const Appearance DOOR_NORTH_R = { '+', colors::BROWN, 0 * 16 + 6 };
const Appearance DOOR_EAST_U = { '+', colors::BROWN, 0 * 16 + 10 };
const Appearance DOOR_EAST_L = { '+', colors::BROWN, 1 * 16 + 10 };
const Appearance DOOR_SOUTH_L = { '+', colors::BROWN, 1 * 16 + 7 };
const Appearance DOOR_SOUTH_R = { '+', colors::BROWN, 1 * 16 + 8 };
const Appearance DOOR_WEST_U = { '+', colors::BROWN, 0 * 16 + 11 };
const Appearance DOOR_WEST_L = { '+', colors::BROWN, 1 * 16 + 11 };

const Appearance PLAYER_NAKED = { '@', {255, 255, 255, 255}, 66 };
const Appearance WARRIOR_IDLE1 = { '@', {255, 255, 255, 255}, 6 * 16 + 2 };
const Appearance WARRIOR_IDLE2 = { '@', {255, 255, 255, 255}, 6 * 16 + 1 };
const Appearance WARRIOR_POINT = { '@', {255, 255, 255, 255}, 6 * 16 + 0 };

const Appearance GOBLIN_IDLE1 = { 'g', {0, 255, 0, 255}, 9 * 16 + 5 };
const Appearance GOBLIN_IDLE2 = { 'g', {0, 255, 0, 255}, 9 * 16 + 4 };
const Appearance GOBLIN_POINT = { 'g', {0, 255, 0, 255}, 9 * 16 + 3 };
